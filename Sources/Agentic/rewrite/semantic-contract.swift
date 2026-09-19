import Schema

public enum Contract {
    public enum Semantic {
        public protocol Object:
            Sendable,
            Codable
        {}

        public protocol SchematizableObject:
            Sendable,
            Codable,
            JSONSchemaProviding
        {}
    }

    public enum Process {
        public enum Tool {
            public typealias Source = Sendable & Decodable & JSONSchemaProviding
            public typealias Result = Sendable & Encodable
        }

        public enum Inference {
            public typealias Source = Sendable & Codable
            public typealias Result = Sendable & Codable & JSONSchemaProviding
        }

        public enum Program {
            public typealias Source = Sendable & Codable
            public typealias Result = Sendable & Codable
        }
    }

    // for possible divergence:
    public typealias Source = Contract.Semantic.SchematizableObject
    public typealias Result = Contract.Semantic.SchematizableObject

    // for uniformity of the objects:
    public typealias Product = Source & Result
}

public typealias Source = Contract.Source
public typealias Result = Contract.Result

public typealias Product = Contract.Product

// technically:
// ALL require Sendable
// and in addition:
// ToolInput: Decodable, JSONSchemaProviding
// ToolOutput: Encodable
// InferenceInput: Codable
// InferenceOutput: Codable, JSONSchemaProviding
// ergo, it is easiest to make Producer -> Codable, Sendable, JSONSchemaProviding
// 
// to reduce the compiler errors around Macro-based protocol conformances:
// simplify the name of the protocol vs the type

public protocol Producer: Sendable {
    associatedtype Input: Source
    associatedtype Output: Result

    // associatedtype Source: Contract.Source
    // associatedtype Result: Contract.Result

    // @available(*, message: "use Source")
    // typealias Input = Source

    // @available(*, message: "use Result")
    // typealias Output = Result
}

// public protocol InferredOutput:
//     SemanticOutput,
//     JSONSchemaProviding
// {}

// public protocol SemanticContract: Sendable {
//     associatedtype Input: SemanticInput
//     associatedtype Output: SemanticOutput
// }

// public protocol InferenceContract:
//     SemanticContract
// where Output: InferredOutput
// {}
