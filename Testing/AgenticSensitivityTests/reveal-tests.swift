import Agentic
import AgenticSensitivity
import Foundation
import Sensitivity
import Testing

/// Showing the owner what handles stand for, without changing what models and records hold.
enum RevealTests {
    static func segmentsAndModes() async throws {
        let vault = Sensitivity.Vault(lifetime: .seconds(60))
        let sam = await vault.handle(for: "sam@example.com", kind: .contact, tier: .handle, detector: "email", reason: "address", score: 90, source: "mail_read")
        let key = await vault.handle(for: "sk-test-1234567890abcdef", kind: .secret, tier: .handle, detector: "token", reason: "key", score: 95, source: "read_file")
        let entries = await vault.displayEntries()
        let gone = Sensitivity.Handle(kind: .contact, id: "00000000")
        let text = "From \(sam.token) with \(key.token);\(gone.token) ⟦contact:zz⟧ end"

        let revealed = Privacy.Reveal(mode: .revealed, entries: entries)
        let segments = revealed.segments(in: text)
        try Expect.equal(segments.count, 7, "text and handles alternate, malformed left as text")
        try Expect.equal(segments.first, .text("From "), "leading text")
        guard case .handle(let shown) = segments[1], case .handle(let secret) = segments[3], case .handle(let unknown) = segments[5] else {
            throw TestFlowAssertionFailure(label: "segments", message: "\(segments)")
        }
        try Expect.equal(shown.state, .revealed, "a contact is revealed")
        try Expect.equal(shown.text, "sam@example.com", "as its value")
        try Expect.equal(shown.description?.sources, ["mail_read"], "with where it was seen, for a hover")
        try Expect.equal(secret.state, .masked, "a secret stays masked inline")
        try Expect.false(secret.text.contains("1234567890"), "no secret value inline: \(secret.text)")
        try Expect.equal(revealed.value(of: key), "sk-test-1234567890abcdef", "only on an explicit reveal")
        try Expect.equal(unknown.state, .unknown, "an unknown handle")
        try Expect.equal(unknown.text, gone.token, "stays a handle")
        try Expect.equal(segments.last, .text(" ⟦contact:zz⟧ end"), "a malformed handle is text")
        try Expect.equal(revealed.plain("to \(sam.token)"), "to sam@example.com", "plain text for unstyled surfaces")

        let masked = Privacy.Reveal(mode: .masked, entries: entries)
        try Expect.false(masked.plain(sam.token).contains("sam@example.com"), "masked mode shows previews only")
        try Expect.equal(Privacy.Reveal.handles.plain(text), text, "handles mode changes nothing")
        try Expect.equal(revealed.plain("no handles here"), "no handles here", "text without handles")
    }

    static func displayConfiguration() throws {
        try Expect.equal(Privacy.Configuration.standard.display, .revealed, "values on the owner's screens by default")
        let masked = try Privacy.Configuration(source: "import Sensitivity;\nlet display: Display = .{ .mode = .masked };")
        try Expect.equal(masked.display, .masked, "set in sensitivity.frame")
        let example = try Privacy.Configuration(source: SensitivityFrame.example)
        try Expect.equal(example.display, .revealed, "the example declares it")
        let template = try Privacy.Configuration(source: SensitivityFrame.template)
        try Expect.equal(template.display, .revealed, "and the template")
    }
}
