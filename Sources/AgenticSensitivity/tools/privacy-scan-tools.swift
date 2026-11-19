import Agentic
import Foundation
import Macros
import Primitives
import Schema
import Sensitivity

public extension Privacy.Tools {
    @JSONSchema
    struct FindingItem: HashableResult {
        public let kind: String
        /// handle, soft or flag (kept, listed for review).
        public let tier: String
        /// Masked.
        public let preview: String
        public let detector: String
        public let reason: String
        public let score: Int
    }

    @Tool("privacy_scan")
    struct Scan {
        @JSONSchema
        public struct Input: HashableSource {
            public let text: String
            /// Presets to use: secrets, contacts, financial, payments,
            /// network, links. All by default.
            public let presets: [String]?

            public init(text: String, presets: [String]? = nil) {
                self.text = text
                self.presets = presets
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let clean: Bool
            public let findings: [FindingItem]
        }

        public static let purpose =
            "Find sensitive data in a text, before it is committed, published or shared: kind, tier, masked preview and why. Values are never shown."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let policy = (context.payloadGuard as? Privacy.Guard)?.shield.policy ?? .standard
            let presets = input.presets.map { $0.compactMap(Sensitivity.Preset.named) } ?? policy.presets
            let findings = Sensitivity.scan(input.text, presets: presets)
            return .init(
                clean: findings.isEmpty,
                findings: findings.map { finding in
                    .init(
                        kind: finding.kind.rawValue,
                        tier: policy.tier(for: finding).rawValue,
                        preview: Sensitivity.mask(finding.text),
                        detector: finding.detector,
                        reason: finding.reason,
                        score: finding.score.raw
                    )
                }
            )
        }
    }

    @Tool("privacy_preview")
    struct Preview {
        @JSONSchema
        public struct Input: HashableSource {
            /// A plain text payload.
            public let text: String?
            /// A JSON payload; fields are reported by path.
            public let json: JSONValue?
            /// The tool the payload comes from, for the header.
            public let source: String?

            public init(text: String? = nil, json: JSONValue? = nil, source: String? = nil) {
                self.text = text
                self.json = json
                self.source = source
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            /// Markdown: verdict and counts, changed fields with masked
            /// originals, then the payload as it leaves.
            public let preview: String
        }

        public static let purpose =
            "Show how a payload leaves once protected: verdict, counts per kind, each replaced or flagged field with a masked original, and the protected payload."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let shield = try Privacy.activeGuard(in: context).shield
            let source = input.source ?? "payload"
            if let json = input.json {
                let (protected, protection) = await shield.protect(json, source: source)
                return .init(preview: Sensitivity.preview(source: source, protection: protection, payload: protected.prettyText))
            }
            let (protected, protection) = await shield.protect(input.text ?? "", source: source)
            return .init(preview: Sensitivity.preview(source: source, protection: protection, payload: protected))
        }
    }
}

extension JSONValue {
    /// Sorted, indented JSON for reading.
    var prettyText: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return (try? encoder.encode(self)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }
}
