import Foundation
import Macros
import Primitives

public extension AgentModel {
    struct Artifact:
        Sendable,
        Codable,
        Hashable,
        Identifiable
    {
        public let id: ID
        public let model: AgentModel.ID
        public let format: Format
        public let precision: Precision?
        public let quantization: Quantization?
        public let bytes: UInt64?
        public let shards: UInt?
        public let source: Source?
        public let checksum: Checksum?

        public init(
            id: ID,
            model: AgentModel.ID,
            format: Format,
            precision: Precision? = nil,
            quantization: Quantization? = nil,
            bytes: UInt64? = nil,
            shards: UInt? = nil,
            source: Source? = nil,
            checksum: Checksum? = nil
        ) {
            self.id = id
            self.model = model
            self.format = format
            self.precision = precision
            self.quantization = quantization
            self.bytes = bytes
            self.shards = shards
            self.source = source
            self.checksum = checksum
        }
    }
}

public extension AgentModel.Artifact {
    struct ID: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    struct Format: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    struct Precision: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    struct Quantization:
        Sendable,
        Codable,
        Hashable
    {
        public let scheme: Scheme
        public let bits: Double?
        public let group: UInt?

        public init(
            scheme: Scheme,
            bits: Double? = nil,
            group: UInt? = nil
        ) {
            self.scheme = scheme
            self.bits = bits
            self.group = group
        }
    }

    struct Source:
        Sendable,
        Codable,
        Hashable
    {
        public let url: URL

        public init(
            url: URL
        ) {
            self.url = url
        }
    }

    struct Checksum:
        Sendable,
        Codable,
        Hashable
    {
        public let algorithm: Algorithm
        public let value: String

        public init(
            algorithm: Algorithm,
            value: String
        ) {
            self.algorithm = algorithm
            self.value = value
        }
    }
}

public extension AgentModel.Artifact.Quantization {
    struct Scheme: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

public extension AgentModel.Artifact.Checksum {
    struct Algorithm: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

@StringIdentifiers
public extension AgentModel.Artifact.Format {
    static var safetensors: Self
    static var gguf: Self
    static var mlx: Self
    static var coreml: Self
    static var onnx: Self
}

@StringIdentifiers
public extension AgentModel.Artifact.Precision {
    static var bf16: Self
    static var fp16: Self
    static var fp32: Self
    static var fp8: Self
}

@StringIdentifiers
public extension AgentModel.Artifact.Quantization.Scheme {
    static var q4_k_m: Self
    static var q5_k_m: Self
    static var q8_0: Self
    static var awq: Self
    static var gptq: Self
}

@StringIdentifiers
public extension AgentModel.Artifact.Checksum.Algorithm {
    static var sha256: Self
    static var sha512: Self
}
