import Agentic
import AgenticConfiguration
import AgenticSensitivity
import Foundation
import Macros
import Primitives
import Schema
import Sensitivity
import Testing

/// Fixture domains: a mail domain whose tools share values, and a web
/// domain that needs a grant. All values are invented.
@Domain
enum FixtureMail {}

@Domain
enum FixtureWeb {}

/// What tools received, as they received it.
actor Received {
    static let shared = Received()
    private(set) var values: [String] = []

    func append(_ value: String) {
        values.append(value)
    }

    func last() -> String? {
        values.last
    }
}

extension FixtureMail.Tools {
    @Tool("mail_lookup")
    struct Lookup {
        @JSONSchema
        struct Input: HashableSource {
            let name: String
        }

        @JSONSchema
        struct Output: HashableResult {
            let address: String
            let note: String
        }

        static let purpose = "Look up a client's address."
        static let risk: ActionRisk = .observe

        init() {}

        func call(_ input: Input, in context: CapabilityContext) async throws -> Output {
            .init(address: "sam@example.com", note: "Prefers calls on 06 00 00 00 00.")
        }
    }

    @Tool("mail_send")
    struct Send {
        @JSONSchema
        struct Input: HashableSource {
            let to: String
            let body: String
        }

        @JSONSchema
        struct Output: HashableResult {
            let sent: String
        }

        static let purpose = "Send a mail."
        static let risk: ActionRisk = .observe

        init() {}

        func preflight(_ input: Input, in context: CapabilityContext) async throws -> ToolPreflight {
            await Received.shared.append("preflight \(input.to)")
            return .init(tool: Self.identifier, risk: Self.risk, summary: "Send to \(input.to)", warnings: ["Recipient \(input.to) is external."])
        }

        func call(_ input: Input, in context: CapabilityContext) async throws -> Output {
            await Received.shared.append(input.to)
            return .init(sent: "sent to \(input.to)")
        }
    }
}

extension FixtureWeb.Tools {
    @Tool("web_fetch")
    struct Fetch {
        @JSONSchema
        struct Input: HashableSource {
            let url: String
        }

        @JSONSchema
        struct Output: HashableResult {
            let fetched: Bool
        }

        static let purpose = "Fetch a page."
        static let risk: ActionRisk = .observe

        init() {}

        func call(_ input: Input, in context: CapabilityContext) async throws -> Output {
            await Received.shared.append(input.url)
            return .init(fetched: true)
        }
    }
}

enum GuardTests {
    static func context() throws -> (CapabilityContext, Privacy.Guard) {
        let installed = Privacy.Guard()
        return (CapabilityContext(services: try CapabilityServices().inserting(ToolPayloadGuarding(installed))), installed)
    }

    static func run<T: Tool>(_ tool: T, _ arguments: JSONValue, in context: CapabilityContext) async throws -> FunctionCall.Response {
        let binding = ToolBinding(tool)
        let call = ToolInvocation(id: UUID().uuidString, tool: binding.definition.identifier, arguments: arguments)
        return try await binding.execute(call, context: context).result
    }

    static func handle(in response: FunctionCall.Response, kind: Sensitivity.Kind) throws -> Sensitivity.Handle {
        try Expect.notNil(
            Sensitivity.Handle.occurrences(in: response.modelText).first { $0.handle.kind == kind }?.handle,
            "a \(kind.rawValue) handle in \(response.modelText)"
        )
    }

    static func resultsLeaveWithHandles() async throws {
        let (context, _) = try context()
        let response = try await run(FixtureMail.Tools.Lookup(), .object(["name": .string("Sam")]), in: context)
        try Expect.false(response.modelText.contains("sam@example.com"), "the model never reads the address: \(response.modelText)")
        try Expect.false(response.modelText.contains("06 00 00 00 00"), "nor the number")
        _ = try handle(in: response, kind: .contact)
    }

    static func relatedToolsUseValues() async throws {
        let (context, _) = try context()
        let lookup = try await run(FixtureMail.Tools.Lookup(), .object(["name": .string("Sam")]), in: context)
        let address = try handle(in: lookup, kind: .contact)

        let sent = try await run(
            FixtureMail.Tools.Send(),
            .object(["to": .string(address.token), "body": .string("Hi")]),
            in: context
        )
        try Expect.equal(await Received.shared.last(), "sam@example.com", "the related tool works with the value")
        try Expect.equal(sent.modelText.contains(address.token), true, "and its own result shows the same handle: \(sent.modelText)")
        try Expect.false(sent.modelText.contains("sam@example.com"), "never the value")
    }

    static func reviewsShowHandles() async throws {
        let (context, _) = try context()
        let lookup = try await run(FixtureMail.Tools.Lookup(), .object(["name": .string("Sam")]), in: context)
        let address = try handle(in: lookup, kind: .contact)

        let binding = ToolBinding(FixtureMail.Tools.Send())
        let call = ToolInvocation(
            id: "review",
            tool: binding.definition.identifier,
            arguments: .object(["to": .string(address.token), "body": .string("Hi")])
        )
        let review = try await binding.prepare(call, context: context).review
        try Expect.equal(await Received.shared.last(), "preflight sam@example.com", "preflight works with the value")
        try Expect.equal(review.summary, "Send to \(address.token)", "the review an approval shows holds the handle")
        try Expect.equal(review.warnings, ["Recipient \(address.token) is external."], "warnings too")
    }

    static func otherDomainsNeedAGrant() async throws {
        let (context, installed) = try context()
        let lookup = try await run(FixtureMail.Tools.Lookup(), .object(["name": .string("Sam")]), in: context)
        let address = try handle(in: lookup, kind: .contact)
        let arguments: JSONValue = .object(["url": .string("https://example.com/?to=\(address.token)")])

        var refusal: (any Error)?
        do {
            _ = try await run(FixtureWeb.Tools.Fetch(), arguments, in: context)
        } catch {
            refusal = error
        }
        try Expect.true(refusal is Privacy.GuardFailure, "another domain is refused: \(String(describing: refusal))")
        try Expect.true((refusal as? Privacy.GuardFailure)?.errorDescription?.contains("privacy_tool_grant") == true, "the refusal says how to ask")

        let granted = try await Privacy.Tools.Grant().call(
            .init(handle: address.token, tool: "web_fetch", purpose: "check the address"),
            in: context
        )
        try Expect.true(granted.granted, "the owner grants it")
        _ = try await run(FixtureWeb.Tools.Fetch(), arguments, in: context)
        try Expect.equal(await Received.shared.last(), "https://example.com/?to=sam@example.com", "granted now, resolved inside the call")
        try Expect.equal(await installed.vault.describe(address)?.grants, ["web_fetch"], "the grant is recorded on the handle")
    }

    static func ownerValuesGoAnywhere() async throws {
        let (context, installed) = try context()
        let prompt = await installed.protecting("Send the offer to noor@example.com", from: ToolIdentifier("owner"))
        let address = try Expect.notNil(Sensitivity.Handle.occurrences(in: prompt).first?.handle, "the owner's value becomes a handle: \(prompt)")
        _ = try await run(FixtureWeb.Tools.Fetch(), .object(["url": .string("https://example.com/?to=\(address.token)")]), in: context)
        try Expect.equal(await Received.shared.last(), "https://example.com/?to=noor@example.com", "a value the owner supplied needs no grant")
    }

    static func handlesAndPreviewNeverShowValues() async throws {
        let (context, _) = try context()
        _ = try await run(FixtureMail.Tools.Lookup(), .object(["name": .string("Sam")]), in: context)

        let handles = try await Privacy.Tools.Handles().call(.init(), in: context)
        try Expect.equal(handles.handles.count, 2, "address and number")
        try Expect.equal(handles.handles.first?.sources, ["mail_lookup address"], "where it was seen: tool and field path")
        let encoded = String(decoding: try JSONEncoder().encode(handles), as: UTF8.self)
        try Expect.false(encoded.contains("sam@example.com"), "no values in the description: \(encoded)")

        let preview = try await Privacy.Tools.Preview().call(
            .init(json: .object(["iban": .string("NL91ABNA0417164300")]), source: "bunq_payments"),
            in: context
        )
        try Expect.true(preview.preview.contains("**************4300"), "masked original")
        try Expect.false(preview.preview.contains("NL91ABNA0417164300"), "never the value")
    }

    static func scrubSession() async throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent("agentic-home-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: home) }
        setenv("AGENTIC_HOME", home.path, 1)
        defer { unsetenv("AGENTIC_HOME") }

        let session = "SESSION-FIXTURE"
        let directory = AgentHomeLocator().resolveHome().layout.runtimeStorage.sessiondir(sessionID: session)
        try FileManager.default.createDirectory(at: directory.appendingPathComponent("payloads"), withIntermediateDirectories: true)
        let log = directory.appendingPathComponent("log.jsonl")
        try """
            {"kind":"message","text":"Mail sam@example.com about Pip"}
            {"kind":"tool","output":{"iban":"NL91ABNA0417164300"}}
            plain line without anything
            """.write(to: log, atomically: true, encoding: .utf8)
        try #"{"note":"call 06 00 00 00 00"}"#.write(to: directory.appendingPathComponent("payloads/p1.json"), atomically: true, encoding: .utf8)

        let (context, _) = try context()
        let dry = try await Privacy.Tools.ScrubSession().call(.init(session: session), in: context)
        try Expect.true(dry.dry_run, "a dry run by default")
        try Expect.equal(dry.files_scanned, 2, "log and payload")
        try Expect.equal(dry.files_changed, ["log.jsonl", "payloads/p1.json"], "both would change")
        try Expect.true(try String(contentsOf: log, encoding: .utf8).contains("sam@example.com"), "a dry run writes nothing")

        let written = try await Privacy.Tools.ScrubSession().call(.init(session: session, dry_run: false), in: context)
        try Expect.equal(written.replaced.map(\.kind), ["contact", "financial"], "kinds replaced")
        let scrubbed = try String(contentsOf: log, encoding: .utf8)
        try Expect.false(scrubbed.contains("sam@example.com") || scrubbed.contains("NL91ABNA0417164300"), "values gone: \(scrubbed)")
        try Expect.true(scrubbed.contains("plain line without anything"), "the rest untouched")
        let report = String(decoding: try JSONEncoder().encode(written), as: UTF8.self)
        try Expect.false(report.contains("example.com"), "the report itself holds no values")

        var invalid: (any Error)?
        do {
            _ = try await Privacy.Tools.ScrubSession().call(.init(session: "../etc"), in: context)
        } catch {
            invalid = error
        }
        try Expect.notNil(invalid, "a path outside sessions is refused")
    }
}
