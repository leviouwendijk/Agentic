import Agentic
import Macros
import Primitives
import Schema

public enum CallCapabilityError: Error, Sendable, CustomStringConvertible {
    case notAvailable(String)
    case direct(String)

    public var description: String {
        switch self {
        case .notAvailable(let identifier):
            "'\(identifier)' is not available to call: find it with list_capabilities or search_capabilities, then read its contract with inspect_capability."
        case .direct(let identifier):
            "'\(identifier)' is in your tool definitions: call it by its own name."
        }
    }
}

public extension Standard.Tools {
    /// Calls an available capability that is not among the tool definitions.
    /// The provider's tool definitions stay as the conversation opened,
    /// because any change to them rewrites the whole cached prompt; the
    /// rest is called through this one definition instead. The runtime turns the
    /// call into a call of the capability itself, under its own approval,
    /// preflight and record, so this tool only runs when that fails.
    @Tool
    struct CallCapability: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            /// The capability, as inspect_capability named it. A shorter form
            /// (`domain.name`, or a bare name) works when it is unambiguous.
            public let identifier: String
            /// Its domain, only when a bare name is shared by several domains.
            public let domain: String?
            /// Its input, as its contract describes.
            public let input: JSONValue

            public init(identifier: String, domain: String? = nil, input: JSONValue) {
                self.identifier = identifier
                self.domain = domain
                self.input = input
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let identifier: String

            public init(identifier: String) {
                self.identifier = identifier
            }
        }

        public static let purpose =
            "Only for a capability that is not among your tools: call it here with its identifier and its input as inspect_capability's contract describes. Call every tool you have by its own name, never through this one."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            if let visible = await context.capabilities?.snapshot().visible,
               visible.tools.contains(ToolIdentifier(input.identifier)) {
                throw CallCapabilityError.direct(input.identifier)
            }
            // The runtime dispatches every call that names exactly one
            // capability; this one did not. Say why when the reason is the
            // name itself (ambiguous, unknown domain).
            if let (_, available) = try? await CapabilityDiscovery.available(in: context) {
                let kinds: [CapabilityKind] = (try? CapabilityIdentity(input.identifier)).map { [$0.kind] } ?? CapabilityKind.allCases
                for kind in kinds {
                    do {
                        _ = try CapabilityReference(.init(
                            input.identifier,
                            domain: input.domain,
                            kind: kind,
                            domains: context.catalog.domains,
                            offered: available.map(\.reference)
                        ))
                    } catch CapabilityReferenceError.notFound {
                        continue
                    } catch {
                        throw error
                    }
                }
            }
            throw CallCapabilityError.notAvailable(input.identifier)
        }
    }
}
