import Agentic
import Macros
import Schema

/// Domains with primary names: their tools get computed identifiers.
@Domain("fixture", aliases: ["fx", "fixtures"])
public enum NamedCatalogFixture {}

@Domain("other")
public enum OtherCatalogFixture {}

public extension NamedCatalogFixture.Tools {
    @Tool("build")
    struct Build: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            public init() {}
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let value: String

            public init(value: String) {
                self.value = value
            }
        }

        public static let purpose = "Named domain fixture: build."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(_ input: Input, in context: CapabilityContext) async throws -> Output {
            Output(value: "fixture")
        }
    }

    @Tool("run_product")
    struct RunProduct: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            public init() {}
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let value: String

            public init(value: String) {
                self.value = value
            }
        }

        public static let purpose = "Named domain fixture: a name with an underscore."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(_ input: Input, in context: CapabilityContext) async throws -> Output {
            Output(value: "run")
        }
    }
}

public extension OtherCatalogFixture.Tools {
    @Tool("build")
    struct Build: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            public init() {}
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let value: String

            public init(value: String) {
                self.value = value
            }
        }

        public static let purpose = "Second named domain fixture: build again."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(_ input: Input, in context: CapabilityContext) async throws -> Output {
            Output(value: "other")
        }
    }
}
