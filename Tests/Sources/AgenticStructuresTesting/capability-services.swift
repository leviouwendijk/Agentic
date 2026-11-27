import Agentic

private actor CapabilityServicesProbe {}
private struct CapabilityServicesAbsentProbe: Sendable {}

private enum CapabilityServicesSmokeFailure: Error {
    case expected_rejection
}

enum CapabilityServicesSmoke {
    static func run() throws {
        let original = CapabilityServicesProbe()
        let services = try CapabilityServices().inserting(original)
        let context = CapabilityContext(services: services)
        let targeted = context.using(workspace: nil)

        let resolved = try targeted.require(CapabilityServicesProbe.self)
        try AgenticStructuresSmoke.check(
            resolved === original,
            "workspace targeting preserves the same service actor"
        )

        do {
            _ = try targeted.require(CapabilityServicesAbsentProbe.self)
            throw CapabilityServicesSmokeFailure.expected_rejection
        } catch CapabilityServices.Failure.missing_type(_) {
        }

        do {
            _ = try services.inserting(CapabilityServicesProbe())
            throw CapabilityServicesSmokeFailure.expected_rejection
        } catch CapabilityServices.Failure.duplicate_type(_) {
        }

        let separate = CapabilityContext(services: .init())
        do {
            _ = try separate.require(CapabilityServicesProbe.self)
            throw CapabilityServicesSmokeFailure.expected_rejection
        } catch CapabilityServices.Failure.missing_type(_) {
        }

        print("CapabilityServices smoke: passed")
    }
}
