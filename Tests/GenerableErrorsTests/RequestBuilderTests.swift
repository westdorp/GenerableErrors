import Testing
@testable import GenerableErrors

@Suite("RequestBuilder")
struct RequestBuilderTests {

    @Test("builds request from ErrorDescriptor and ErrorStyle")
    func buildsRequest() throws {
        let style = TestStyle(promptHint: "Write a haiku.", temperature: 0.8)
        let builder = RequestBuilder.default

        let request = try builder.makeRequest(for: notFound, style: style)

        #expect(request.instructions.contains("creative writer"))
        #expect(request.prompt.contains("Error Code: 404 Not Found"))
        #expect(request.prompt.contains("Write a haiku."))
        #expect(request.temperature == 0.8)
    }

    @Test("prompt includes error explanation")
    func promptIncludesExplanation() throws {
        let style = TestStyle(promptHint: "Be snarky.", temperature: 1.0)
        let builder = RequestBuilder.default

        let request = try builder.makeRequest(for: teapot, style: style)

        #expect(request.prompt.contains(teapot.explanation))
    }

    @Test(
        "temperature is clamped to 0.0...1.0",
        arguments: [
            (2.5, 1.0),
            (-0.5, 0.0),
            (0.7, 0.7),
            (0.0, 0.0),
            (1.0, 1.0),
        ]
    )
    func temperatureIsClamped(input: Double, expected: Double) throws {
        let style = TestStyle(promptHint: "Test.", temperature: input)
        let builder = RequestBuilder.default

        let request = try builder.makeRequest(for: teapot, style: style)

        #expect(request.temperature == expected)
    }

    @Test("custom instructions are preserved")
    func customInstructionsPreserved() throws {
        let builder = RequestBuilder(instructions: "Custom instructions")
        let style = TestStyle(promptHint: "Test.", temperature: 1.0)

        let request = try builder.makeRequest(for: teapot, style: style)

        #expect(request.instructions == "Custom instructions")
    }

    @Test("styles without explicit temperature use protocol default of 1.0")
    func defaultTemperature() throws {
        let style = MinimalStyle(promptHint: "Write a haiku.")
        let builder = RequestBuilder.default

        let request = try builder.makeRequest(for: teapot, style: style)

        #expect(request.temperature == 1.0)
    }

    @Test("consumer-specified temperature overrides default")
    func consumerTemperatureOverride() throws {
        let style = TestStyle(promptHint: "Write a haiku.", temperature: 0.3)
        let builder = RequestBuilder.default

        let request = try builder.makeRequest(for: teapot, style: style)

        #expect(request.temperature == 0.3)
    }

    @Test("system instructions reference generic error codes")
    func systemInstructionsAreGeneric() {
        let instructions = RequestBuilder.defaultInstructions
        #expect(instructions.contains("error"))
        #expect(!instructions.contains("HTTP"))
    }

    @Test("empty descriptor fields fail with invalid request")
    func emptyDescriptorFieldsFail() {
        let style = TestStyle(promptHint: "Test.", temperature: 1.0)
        let builder = RequestBuilder.default
        let invalid = TestError(code: "404", name: " ", explanation: "Meaningful")

        #expect(throws: GenerationError.invalidRequest) {
            _ = try builder.makeRequest(for: invalid, style: style)
        }
    }
}
