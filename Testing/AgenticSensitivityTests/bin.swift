import Agentic
import AgenticSensitivity
import Testing

private enum AgenticSensitivityTestError: Error {
    case failed
}

@main
struct AgenticSensitivityTestMain {
    static func main() async throws {
        let reporter = PlainTextTestReporter()
        let result = await TestRunner.run(
            AgenticSensitivityTestSuite.testSuite,
            sink: reporter
        )
        let rendered = await reporter.rendered()

        if !rendered.isEmpty {
            print(rendered)
        }

        if result.isFailure {
            throw AgenticSensitivityTestError.failed
        }
    }
}

enum AgenticSensitivityTestSuite {
    static let testSuite = TestSuite(
        "agentic-sensitivity",
        title: "AgenticSensitivity: handles through tool calls"
    ) {
        Test("results-leave-with-handles", tags: ["guard", "outbound"]) {
            try await GuardTests.resultsLeaveWithHandles()
        }

        Test("related-tools-use-values", tags: ["guard", "inbound"]) {
            try await GuardTests.relatedToolsUseValues()
        }

        Test("reviews-show-handles", tags: ["guard", "review"]) {
            try await GuardTests.reviewsShowHandles()
        }

        Test("other-domains-need-a-grant", tags: ["guard", "grant"]) {
            try await GuardTests.otherDomainsNeedAGrant()
        }

        Test("owner-values-go-anywhere", tags: ["guard", "owner"]) {
            try await GuardTests.ownerValuesGoAnywhere()
        }

        Test("handles-and-preview-never-show-values", tags: ["tools"]) {
            try await GuardTests.handlesAndPreviewNeverShowValues()
        }

        Test("scrub-session", tags: ["tools", "sessions"]) {
            try await GuardTests.scrubSession()
        }

        Test("configuration-defaults-and-file", tags: ["configuration"]) {
            try ConfigurationTests.defaultsAndFile()
        }

        Test("unreferenced-values-are-swept", tags: ["configuration", "vault"]) {
            try await ConfigurationTests.unreferencedValuesAreSwept()
        }

        Test("session-close-releases", tags: ["configuration", "vault"]) {
            try await ConfigurationTests.sessionCloseReleases()
        }

        Test("pinned-sessions-are-deliberate", tags: ["pin", "scrub"]) {
            try await PinTests.pinnedSessionsAreDeliberate()
        }

        Test("pinned-handles-are-collected", tags: ["pin"]) {
            try await PinTests.pinnedHandlesAreCollected()
        }

        Test("seal-and-unseal", tags: ["pin", "seal"]) {
            try await PinTests.sealAndUnseal()
        }
    }
}
