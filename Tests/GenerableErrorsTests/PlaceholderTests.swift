import Testing
@testable import GenerableErrors

struct TestError: ErrorDescriptor {
    let code: String
    let name: String
    let explanation: String
}

struct TestStyle: ErrorStyle {
    let promptHint: String
    var temperature: Double = 1.0
}

/// Style that relies on the protocol default temperature.
struct MinimalStyle: ErrorStyle {
    let promptHint: String
}

let notFound = TestError(
    code: "404",
    name: "Not Found",
    explanation: "The target resource could not be found on the server."
)

let teapot = TestError(
    code: "418",
    name: "I'm a Teapot",
    explanation: "The server refuses to brew coffee because it is a teapot."
)
