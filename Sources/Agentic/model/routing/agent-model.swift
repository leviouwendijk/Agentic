import Foundation
import Macros
import Primitives

public struct AgentModel:
    Sendable,
    Codable,
    Hashable,
    Identifiable
{
    public typealias ID = AgentModelID

    public let id: ID
    public let title: String
    public let producer: Producer
    public let designation: Designation
    public let lineage: Lineage
    public let architecture: Architecture
    public let interface: Interface
    public let training: Training?
    public let release: Release?
    public let distribution: Distribution?

    public init(
        id: ID,
        title: String,
        producer: Producer,
        designation: Designation,
        lineage: Lineage = .init(),
        architecture: Architecture = .init(),
        interface: Interface = .init(),
        training: Training? = nil,
        release: Release? = nil,
        distribution: Distribution? = nil
    ) {
        self.id = id
        self.title = title
        self.producer = producer
        self.designation = designation
        self.lineage = lineage
        self.architecture = architecture
        self.interface = interface
        self.training = training
        self.release = release
        self.distribution = distribution
    }
}

public extension AgentModel {
    struct Producer: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    struct Family: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    struct Series: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    struct Tier: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    struct Specialization: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    struct Variant: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    struct Version:
        Sendable,
        Codable,
        Hashable,
        Comparable
    {
        public let generation: UInt
        public let iteration: UInt
        public let revision: UInt

        public init(
            generation: UInt,
            iteration: UInt = 0,
            revision: UInt = 0
        ) {
            self.generation = generation
            self.iteration = iteration
            self.revision = revision
        }

        public static func < (
            lhs: Self,
            rhs: Self
        ) -> Bool {
            if lhs.generation != rhs.generation {
                return lhs.generation < rhs.generation
            }

            if lhs.iteration != rhs.iteration {
                return lhs.iteration < rhs.iteration
            }

            return lhs.revision < rhs.revision
        }
    }

    struct Designation:
        Sendable,
        Codable,
        Hashable
    {
        public let family: Family
        public let version: Version?
        public let series: Series?
        public let tier: Tier?
        public let specializations: Set<Specialization>
        public let variants: [Variant]

        public init(
            family: Family,
            version: Version? = nil,
            series: Series? = nil,
            tier: Tier? = nil,
            specializations: Set<Specialization> = [],
            variants: [Variant] = []
        ) {
            self.family = family
            self.version = version
            self.series = series
            self.tier = tier
            self.specializations = specializations
            self.variants = variants
        }
    }
}

@StringIdentifiers
public extension AgentModel.Producer {
    static var anthropic: Self
    static var amazon: Self
    static var apple: Self
    static var qwen: Self
    static var openai: Self
    static var mistral: Self
    static var moonshot: Self
    static var deepseek: Self
    static var zai: Self
}

@StringIdentifiers
public extension AgentModel.Family {
    static var claude: Self
    static var nova: Self
    static var foundation_models: Self
    static var qwen: Self
    static var gpt_oss: Self
    static var mistral: Self
    static var kimi: Self
    static var deepseek: Self
    static var glm: Self
}

@StringIdentifiers
public extension AgentModel.Specialization {
    static var code: Self
    static var reasoning: Self
    static var vision: Self
    static var audio: Self
}

public extension AgentModel {
    struct Architecture:
        Sendable,
        Codable,
        Hashable
    {
        public let kind: Kind?
        public let topology: Topology?
        public let parameters: Parameters?
        public let experts: Experts?
        public let dimensions: Dimensions?

        public init(
            kind: Kind? = nil,
            topology: Topology? = nil,
            parameters: Parameters? = nil,
            experts: Experts? = nil,
            dimensions: Dimensions? = nil
        ) {
            self.kind = kind
            self.topology = topology
            self.parameters = parameters
            self.experts = experts
            self.dimensions = dimensions
        }
    }
}

public extension AgentModel.Architecture {
    struct Kind: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    enum Topology:
        String,
        Sendable,
        Codable,
        Hashable,
        CaseIterable
    {
        case dense
        case mixture_of_experts
        case hybrid
    }

    struct Parameters:
        Sendable,
        Codable,
        Hashable
    {
        public let total: Count
        public let active: Count?

        public init(
            total: Count,
            active: Count? = nil
        ) {
            self.total = total
            self.active = active
        }
    }

    struct Count:
        Sendable,
        Codable,
        Hashable,
        Comparable,
        RawRepresentable
    {
        public let rawValue: UInt64

        public init(
            rawValue: UInt64
        ) {
            self.rawValue = rawValue
        }

        public static func < (
            lhs: Self,
            rhs: Self
        ) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    struct Experts:
        Sendable,
        Codable,
        Hashable
    {
        public let total: UInt
        public let active: UInt
        public let shared: UInt?

        public init(
            total: UInt,
            active: UInt,
            shared: UInt? = nil
        ) {
            self.total = total
            self.active = active
            self.shared = shared
        }
    }

    struct Dimensions:
        Sendable,
        Codable,
        Hashable
    {
        public let layers: UInt?
        public let hidden: UInt?
        public let intermediate: UInt?
        public let attentionHeads: UInt?
        public let keyValueHeads: UInt?
        public let head: UInt?

        public init(
            layers: UInt? = nil,
            hidden: UInt? = nil,
            intermediate: UInt? = nil,
            attentionHeads: UInt? = nil,
            keyValueHeads: UInt? = nil,
            head: UInt? = nil
        ) {
            self.layers = layers
            self.hidden = hidden
            self.intermediate = intermediate
            self.attentionHeads = attentionHeads
            self.keyValueHeads = keyValueHeads
            self.head = head
        }
    }
}

@StringIdentifiers
public extension AgentModel.Architecture.Kind {
    static var transformer: Self
}

public extension AgentModel.Architecture.Count {
    static func millions(
        _ value: UInt64
    ) -> Self {
        .init(
            rawValue: value * 1_000_000
        )
    }

    static func billions(
        _ value: UInt64
    ) -> Self {
        .init(
            rawValue: value * 1_000_000_000
        )
    }

    static func trillions(
        _ value: UInt64
    ) -> Self {
        .init(
            rawValue: value * 1_000_000_000_000
        )
    }
}

public extension AgentModel {
    struct Interface:
        Sendable,
        Codable,
        Hashable
    {
        public let modalities: Modalities
        public let features: Set<Feature>
        public let tokenizer: Tokenizer?
        public let limits: AgentModelLimits

        public init(
            modalities: Modalities = .init(),
            features: Set<Feature> = [],
            tokenizer: Tokenizer? = nil,
            limits: AgentModelLimits = .unknown
        ) {
            self.modalities = modalities
            self.features = features
            self.tokenizer = tokenizer
            self.limits = limits
        }
    }
}

public extension AgentModel.Interface {
    struct Modalities:
        Sendable,
        Codable,
        Hashable
    {
        public let input: Set<AgentModality>
        public let output: Set<AgentModality>

        public init(
            input: Set<AgentModality> = [],
            output: Set<AgentModality> = []
        ) {
            self.input = input
            self.output = output
        }
    }

    struct Feature: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    struct Tokenizer: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

@StringIdentifiers
public extension AgentModel.Interface.Feature {
    static var tool_use: Self
    static var streaming: Self
    static var structured_output: Self
    static var reasoning: Self
}

public extension AgentModel {
    struct Lineage:
        Sendable,
        Codable,
        Hashable
    {
        public let parents: [Relationship]

        public init(
            parents: [Relationship] = []
        ) {
            self.parents = parents
        }
    }

    struct Relationship:
        Sendable,
        Codable,
        Hashable
    {
        public let model: ID
        public let kind: Kind

        public init(
            model: ID,
            kind: Kind
        ) {
            self.model = model
            self.kind = kind
        }
    }

    struct Date:
        Sendable,
        Codable,
        Hashable
    {
        public let value: Foundation.Date
        public let precision: DatePrecision

        public init(
            value: Foundation.Date,
            precision: DatePrecision
        ) {
            self.value = value
            self.precision = precision
        }
    }

    struct Training:
        Sendable,
        Codable,
        Hashable
    {
        public let stage: Stage?
        public let knowledgeCutoff: Date?

        public init(
            stage: Stage? = nil,
            knowledgeCutoff: Date? = nil
        ) {
            self.stage = stage
            self.knowledgeCutoff = knowledgeCutoff
        }
    }

    struct Release:
        Sendable,
        Codable,
        Hashable
    {
        public let id: ID?
        public let date: Date?
        public let status: Status?

        public init(
            id: ID? = nil,
            date: Date? = nil,
            status: Status? = nil
        ) {
            self.id = id
            self.date = date
            self.status = status
        }
    }

    struct Distribution:
        Sendable,
        Codable,
        Hashable
    {
        public let channels: Set<Channel>
        public let license: License?
        public let homepage: URL?
        public let repository: URL?

        public init(
            channels: Set<Channel> = [],
            license: License? = nil,
            homepage: URL? = nil,
            repository: URL? = nil
        ) {
            self.channels = channels
            self.license = license
            self.homepage = homepage
            self.repository = repository
        }
    }
}

public extension AgentModel.Relationship {
    enum Kind:
        String,
        Sendable,
        Codable,
        Hashable,
        CaseIterable
    {
        case derived_from
        case fine_tuned_from
        case distilled_from
        case continued_pretraining_from
        case merged_from
    }
}

public extension AgentModel.Training {
    struct Stage: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

@StringIdentifiers
public extension AgentModel.Training.Stage {
    static var base: Self
    static var pretrained: Self
    static var instruction_tuned: Self
    static var chat_tuned: Self
    static var reasoning_tuned: Self
    static var code_tuned: Self
}

public extension AgentModel.Release {
    struct ID: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    enum Status:
        String,
        Sendable,
        Codable,
        Hashable,
        CaseIterable
    {
        case preview
        case stable
        case deprecated
        case retired
    }
}

public extension AgentModel.Distribution {
    enum Channel:
        String,
        Sendable,
        Codable,
        Hashable,
        CaseIterable
    {
        case api
        case open_weights
        case downloadable
        case on_device
    }

    struct License: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}
