enum AvailabilityMonitorClockError: Error, Equatable, Sendable {
    case cancelled
    case failed
}

@MainActor
protocol AvailabilityMonitorClock {
    func sleep(for duration: Duration) async throws(AvailabilityMonitorClockError)
}

struct ContinuousAvailabilityMonitorClock: AvailabilityMonitorClock {
    private let clock = ContinuousClock()

    @MainActor
    func sleep(for duration: Duration) async throws(AvailabilityMonitorClockError) {
        do {
            try await clock.sleep(for: duration)
        } catch is CancellationError {
            throw .cancelled
        } catch {
            throw .failed
        }
    }
}
