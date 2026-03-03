import GenerableErrors
import GenerableErrorsTesting
import Testing
@testable import GenerableErrorsApp

extension GenerationState {
    var codeSelection: ErrorGeneration.Selection? {
        guard case .codeSelected(let selection) = self else { return nil }
        return selection
    }

    var errorFailure: ErrorGeneration.FailureState? {
        guard case .error(let state) = self else { return nil }
        return state
    }
}

enum HTTPErrorFixtureError: Error, Equatable {
    case missingCode(Int)
}

private enum HTTPErrorFixtures {
    static let byCode: [Int: HTTPError] = [
        400: HTTPError(
            id: 400,
            name: "Bad Request",
            rfc: "RFC 9110",
            explanation: "The server cannot process the request due to malformed syntax."
        ),
        403: HTTPError(
            id: 403,
            name: "Forbidden",
            rfc: "RFC 9110",
            explanation: "The server understood the request but refuses to authorize it."
        ),
        404: HTTPError(
            id: 404,
            name: "Not Found",
            rfc: "RFC 9110",
            explanation: "The target resource could not be found on the server."
        ),
        409: HTTPError(
            id: 409,
            name: "Conflict",
            rfc: "RFC 9110",
            explanation: "The request conflicts with the current state of the target resource."
        ),
        418: HTTPError(
            id: 418,
            name: "I'm a Teapot",
            rfc: "RFC 2324",
            explanation: "The server refuses to brew coffee because it is a teapot."
        ),
    ]
}

func httpError(_ code: Int) throws(HTTPErrorFixtureError) -> HTTPError {
    guard let error = HTTPErrorFixtures.byCode[code] else {
        throw .missingCode(code)
    }
    return error
}

func generatedSnapshot(meaning: String?, message: String?) -> GeneratedSnapshot {
    guard let snapshot = GeneratedSnapshot(meaning: meaning, message: message) else {
        fatalError("GeneratedSnapshot must include at least one field")
    }
    return snapshot
}

@MainActor
final class TestAvailabilityMonitorClock: AvailabilityMonitorClock {
    private var outcomes: [Result<Void, AvailabilityMonitorClockError>]
    private let onSleep: (() -> Void)?

    init(
        outcomes: [Result<Void, AvailabilityMonitorClockError>] = [.failure(.cancelled)],
        onSleep: (() -> Void)? = nil
    ) {
        self.outcomes = outcomes
        self.onSleep = onSleep
    }

    func sleep(for duration: Duration) async throws(AvailabilityMonitorClockError) {
        onSleep?()
        guard !outcomes.isEmpty else {
            throw .cancelled
        }
        switch outcomes.removeFirst() {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
