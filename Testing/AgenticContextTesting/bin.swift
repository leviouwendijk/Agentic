import Agentic
import AgenticContext
import Testing

private enum ContextFilesTestError: Error {
    case failed
}

@main
struct ContextFilesTestMain {
    static func main() async throws {
        let reporter = PlainTextTestReporter()
        let result = await TestRunner.run(
            ContextFilesTestSuite.testSuite,
            sink: reporter
        )
        let rendered = await reporter.rendered()

        if !rendered.isEmpty {
            print(rendered)
        }

        if result.isFailure {
            throw ContextFilesTestError.failed
        }
    }
}

enum ContextFilesTestSuite {
    static let testSuite = TestSuite(
        "agentic-context-files",
        title: "AgenticContext: context/*.frame entries"
    ) {
        Test("example-holds", tags: ["context", "frame"]) {
            try ContextFilesTests.exampleHolds()
        }

        Test("library-identifiers", tags: ["context", "library"]) {
            try ContextFilesTests.libraryIdentifiers()
        }

        Test("index-and-read", tags: ["context", "tools"]) {
            try await ContextFilesTests.indexAndRead()
        }

        Test("check-and-save", tags: ["context", "tools", "archive"]) {
            try await ContextFilesTests.checkAndSave()
        }

        Test("groups-defaults-awareness", tags: ["context", "library"]) {
            try await ContextFilesTests.groupsDefaultsAwareness()
        }

        Test("search", tags: ["context", "tools", "search"]) {
            try await ContextFilesTests.search()
        }

        Test("mounts", tags: ["context", "library", "mount"]) {
            try await ContextFilesTests.mounts()
        }
    }
}
