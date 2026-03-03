public enum ModelAvailability: Equatable, Sendable {
    case available
    case unavailable(AvailabilityError)

    public var isAvailable: Bool {
        switch self {
        case .available: true
        case .unavailable: false
        }
    }

    public var unavailabilityMessage: String? {
        switch self {
        case .available: nil
        case .unavailable(let reason): reason.localizedDescription
        }
    }
}
