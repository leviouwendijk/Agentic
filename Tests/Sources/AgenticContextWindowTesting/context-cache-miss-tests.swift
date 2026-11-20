import Agentic
import AgenticContextWindow
import Foundation
import Testing

extension ContextDeterministicFlowTesting {
    /// A shortfall is named by what differs from the previous request to the
    /// same model: content first, then elapsed time; a full read is no miss.
    static func runCacheMisses() async throws {
        let start = Date(timeIntervalSince1970: 0)
        func request(_ texts: [String]) -> AgentRequest {
            .init(messages: texts.enumerated().map { index, text in
                .init(id: "m\(index)", role: index == 0 ? .system : .user, content: .init(text: text))
            })
        }
        func usage(read: Int, written: Int = 0, fresh: Int = 100) -> AgentUsage {
            .init(inputTokens: fresh, cachedInputReadTokens: read, cachedInputWriteTokens: written)
        }

        let meter = ContextWindow.CacheMeter()
        let first = await meter.observe(
            request: request(["system", "a"]), model: "m", usage: usage(read: 0, written: 20_000), startedAt: start
        )
        try Expect.equal(first == nil, true, "The first request to a model has nothing to miss")

        let warm = await meter.observe(
            request: request(["system", "a", "b"]), model: "m",
            usage: usage(read: 20_000), startedAt: start.addingTimeInterval(30)
        )
        try Expect.equal(warm == nil, true, "Reading what the previous request sent is no miss")

        let edited = await meter.observe(
            request: request(["system", "a-edited", "b", "c"]), model: "m",
            usage: usage(read: 500, written: 19_000), startedAt: start.addingTimeInterval(60)
        )
        try Expect.equal(edited?.cause, .content_changed, "An edited message explains the miss")
        try Expect.equal(edited?.divergence, .message(index: 1, id: "m1"), "Named where the prefix diverged")

        let expired = await meter.observe(
            request: request(["system", "a-edited", "b", "c", "d"]), model: "m",
            usage: usage(read: 0, written: 20_000), startedAt: start.addingTimeInterval(60 + 400)
        )
        try Expect.equal(expired?.cause, .expired, "An unchanged prefix past the lifetime expired")

        let dropped = await meter.observe(
            request: request(["system", "a-edited", "b", "c", "d", "e"]), model: "m",
            usage: usage(read: 0, written: 20_000), startedAt: start.addingTimeInterval(60 + 430)
        )
        try Expect.equal(dropped?.cause, .unexplained, "Unchanged and within the lifetime is unexplained")

        let other = await meter.observe(
            request: request(["system"]), model: "other",
            usage: usage(read: 0, written: 20_000), startedAt: start.addingTimeInterval(60 + 440)
        )
        try Expect.equal(other == nil, true, "Caches are per model: another model starts fresh")

        var tools = request(["system", "a-edited", "b", "c", "d", "e", "f"])
        tools.tools = [.init(name: "read_file", description: "Reads a file.", input: .object([:]))]
        let retooled = await meter.observe(
            request: tools, model: "m",
            usage: usage(read: 0, written: 20_000), startedAt: start.addingTimeInterval(60 + 450)
        )
        try Expect.equal(retooled?.divergence, .tools, "A tool change rewrites everything after it")
    }
}
