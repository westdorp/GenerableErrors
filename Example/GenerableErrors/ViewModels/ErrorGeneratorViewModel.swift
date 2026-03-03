import CuratedStyles
import Foundation
import GenerableErrors
import Observation

/// Finite UI states for the error-generation workflow.
///
/// Valid transitions:
/// - `idle` -> `codeSelected`
/// - `codeSelected` -> `generating` or `idle`
/// - `generating` -> `generated`, `error`, or `idle`
/// - `generated` -> `codeSelected`, `generating`, or `idle`
/// - `error` -> `codeSelected`, `generating`, or `idle`
enum GenerationState: Equatable, Sendable {
    case idle(style: AppStyle)
    case codeSelected(ErrorGeneration.Selection)
    case generating(ErrorGeneration.InFlightState)
    case generated(ErrorGeneration.CompletedState)
    case error(ErrorGeneration.FailureState)
}

/// View-layer animation phases derived from `GenerationState`.
enum GenerationAnimationPhase: Equatable, Sendable {
    case idle
    case codeSelected
    case generating
    case generated
    case error
}

/// Coordinates generation requests and exposes a single UI state machine.
@Observable
@MainActor
final class ErrorGeneratorViewModel {

    var generationState: GenerationState = .idle(style: .snarky)
    private(set) var modelAvailability: GenerableErrors.ModelAvailability
    private let catalogResult: Result<HTTPErrorCatalog, HTTPErrorCatalogLoadError>

    private var generationTask: Task<Void, Never>?
    /// Monotonic counter for staleness detection; each generation run captures
    /// the current value and ignores callbacks from older runs.
    private var generationSequence: UInt64 = 0
    private let session: any GenerationSession
    private let availabilityMonitorClock: any AvailabilityMonitorClock
    private let availabilityMonitorInterval: Duration

    var isGenerating: Bool {
        if case .generating = generationState {
            return true
        }
        return false
    }

    var selectedError: HTTPError? {
        generationState.activeSelection?.error
    }

    var selectedStyle: AppStyle {
        generationState.selectedStyle
    }

    var currentResult: GenerableErrors.GeneratedSnapshot? {
        switch generationState {
        case .idle, .codeSelected:
            nil
        case .generating(let state):
            state.partialResult
        case .generated(let state):
            state.result.snapshot
        case .error(let state):
            state.partialResult
        }
    }

    var generationAnimationPhase: GenerationAnimationPhase {
        switch generationState {
        case .idle:
            .idle
        case .codeSelected:
            .codeSelected
        case .generating:
            .generating
        case .generated:
            .generated
        case .error:
            .error
        }
    }

    var canGenerate: Bool {
        selectedError != nil && !isGenerating && modelAvailability.isAvailable
    }

    var groupedErrorCatalog: [(category: HTTPErrorCategory, errors: [HTTPError])] {
        switch catalogResult {
        case .success(let catalog):
            catalog.grouped
        case .failure:
            []
        }
    }

    var catalogLoadMessage: String? {
        guard case .failure(let error) = catalogResult else {
            return nil
        }
        return error.localizedDescription
    }

    init(
        session: any GenerationSession,
        catalogResult: Result<HTTPErrorCatalog, HTTPErrorCatalogLoadError> = .success(
            HTTPErrorCatalog(errors: [])
        ),
        availabilityMonitorClock: any AvailabilityMonitorClock =
            ContinuousAvailabilityMonitorClock(),
        availabilityMonitorInterval: Duration = .seconds(10)
    ) {
        self.session = session
        self.catalogResult = catalogResult
        self.availabilityMonitorClock = availabilityMonitorClock
        self.availabilityMonitorInterval = availabilityMonitorInterval
        self.modelAvailability = session.availability
    }

    // MARK: - Lifecycle

    func refreshModelAvailability() {
        modelAvailability = session.availability
    }

    func monitorModelAvailability() async {
        refreshModelAvailability()
        while true {
            do {
                try await availabilityMonitorClock.sleep(for: availabilityMonitorInterval)
            } catch let error {
                switch error {
                case .cancelled, .failed:
                    return
                }
            }
            refreshModelAvailability()
        }
    }

    // MARK: - Actions

    /// Cancels any in-flight generation.
    func selectError(_ error: HTTPError) {
        if generationTask != nil {
            cancelInFlightGeneration()
            generationSequence &+= 1
        }
        let selection = ErrorGeneration.Selection(error: error, style: selectedStyle)
        generationState = .codeSelected(selection)
    }

    func selectStyle(_ style: AppStyle) {
        generationState = generationState.replacingStyle(style)
    }

    /// Starts generation for the active selection and cancels any in-flight task.
    @discardableResult
    func generate() -> Task<Void, Never> {
        guard let generation = prepareGeneration() else {
            return Task {}
        }

        generationState = .generating(
            ErrorGeneration.InFlightState(selection: generation.selection, partialResult: nil)
        )

        let task = Task { @MainActor in
            await consumeGenerationStream(
                generation.stream,
                generationID: generation.generationID,
                selection: generation.selection
            )
            if generationSequence == generation.generationID {
                generationTask = nil
            }
        }
        generationTask = task
        return task
    }

    /// Cancels in-flight generation and returns to idle while preserving the active style.
    func reset() {
        cancelInFlightGeneration()
        generationSequence &+= 1
        generationState = .idle(style: selectedStyle)
    }
}

extension ErrorGeneratorViewModel {
    fileprivate func cancelInFlightGeneration() {
        generationTask?.cancel()
        generationTask = nil
    }

    fileprivate func prepareGeneration() -> (
        selection: ErrorGeneration.Selection,
        generationID: UInt64,
        stream: GenerationStream
    )? {
        guard let selection = generationState.activeSelection else {
            return nil
        }

        cancelInFlightGeneration()
        generationSequence &+= 1
        let generationID = generationSequence

        refreshModelAvailability()
        if case .unavailable(let reason) = modelAvailability {
            generationState = .error(
                ErrorGeneration.FailureState(
                    selection: selection,
                    error: GenerableErrors.GenerationError.unavailable(reason),
                    partialResult: nil
                )
            )
            return nil
        }

        let stream = session.generate(for: selection.error, style: selection.style)
        return (selection: selection, generationID: generationID, stream: stream)
    }

    fileprivate func consumeGenerationStream(
        _ stream: GenerationStream,
        generationID: UInt64,
        selection: ErrorGeneration.Selection
    ) async {
        var latestPartial: GenerableErrors.GeneratedSnapshot?
        do {
            for try await partialResponse in stream {
                guard !Task.isCancelled else { return }
                guard generationSequence == generationID else { return }
                latestPartial = partialResponse
                generationState = .generating(
                    ErrorGeneration.InFlightState(
                        selection: selection,
                        partialResult: partialResponse
                    )
                )
            }

            guard generationSequence == generationID else { return }
            guard
                let latestPartial,
                let finalResult = ErrorGeneration.FinalResult(snapshot: latestPartial)
            else {
                generationState = .error(
                    ErrorGeneration.FailureState(
                        selection: selection,
                        error: .decodingFailure,
                        partialResult: latestPartial
                    )
                )
                return
            }

            generationState = .generated(
                ErrorGeneration.CompletedState(
                    selection: selection,
                    result: finalResult
                )
            )

        } catch is CancellationError {
            return

        } catch let generationError as GenerableErrors.GenerationError {
            guard generationSequence == generationID else { return }
            generationState = .error(
                ErrorGeneration.FailureState(
                    selection: selection,
                    error: generationError,
                    partialResult: latestPartial
                )
            )

        } catch {
            guard generationSequence == generationID else { return }
            generationState = .error(
                ErrorGeneration.FailureState(
                    selection: selection,
                    error: .unknown,
                    partialResult: latestPartial
                )
            )
        }
    }

}

private extension GenerationState {
    var activeSelection: ErrorGeneration.Selection? {
        switch self {
        case .idle:
            nil
        case .codeSelected(let selection):
            selection
        case .generating(let state):
            state.selection
        case .generated(let state):
            state.selection
        case .error(let state):
            state.selection
        }
    }

    var selectedStyle: AppStyle {
        switch self {
        case .idle(let style):
            style
        case .codeSelected(let selection):
            selection.style
        case .generating(let state):
            state.selection.style
        case .generated(let state):
            state.selection.style
        case .error(let state):
            state.selection.style
        }
    }

    func replacingStyle(_ style: AppStyle) -> Self {
        switch self {
        case .idle:
            .idle(style: style)
        case .codeSelected(let selection):
            .codeSelected(
                ErrorGeneration.Selection(error: selection.error, style: style)
            )
        case .generated(let state):
            .codeSelected(
                ErrorGeneration.Selection(error: state.selection.error, style: style)
            )
        case .error(let state):
            .codeSelected(
                ErrorGeneration.Selection(error: state.selection.error, style: style)
            )
        case .generating:
            self
        }
    }
}
