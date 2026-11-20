import Agentic

private actor ToolServicesProbe {}
private struct ToolServicesAbsentProbe: Sendable {}

private enum ToolServicesSmokeFailure: Error {
    case expected_rejection
}

enum ToolServicesSmoke {
    static func run() throws {
        let original = ToolServicesProbe()
        let services = try ToolServices().inserting(original)
        let context = ToolContext(services: services)
        let targeted = context.using(workspace: nil)

        let resolved = try targeted.require(ToolServicesProbe.self)
        try AgenticStructuresSmoke.check(
            resolved === original,
            "workspace targeting preserves the same service actor"
        )

        do {
            _ = try targeted.require(ToolServicesAbsentProbe.self)
            throw ToolServicesSmokeFailure.expected_rejection
        } catch ToolServices.Failure.missing_type(_) {
        }

        do {
            _ = try services.inserting(ToolServicesProbe())
            throw ToolServicesSmokeFailure.expected_rejection
        } catch ToolServices.Failure.duplicate_type(_) {
        }

        let separate = ToolContext(services: .init())
        do {
            _ = try separate.require(ToolServicesProbe.self)
            throw ToolServicesSmokeFailure.expected_rejection
        } catch ToolServices.Failure.missing_type(_) {
        }

        print("ToolServices smoke: passed")
    }
}
