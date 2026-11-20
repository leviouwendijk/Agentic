public extension CapabilityReference {
    /// The function name a provider is sent for this capability, and the
    /// name the model calls it by. A tool keeps its identifier, already a
    /// function name. Other kinds are their identifier in the provider
    /// alphabet (`[A-Za-z0-9_-]`) behind their kind, so they cannot take a
    /// tool's name; past `providerNameLimit` the name is cut and ends in a
    /// hash of the identifier. Stable across runs.
    var providerName: String {
        if case .tool(let identifier) = self {
            return identifier.rawValue
        }
        return Self.readable(kind: kind, identifier: identifier)
    }

    /// The name when two capabilities would share `providerName`: always
    /// ends in the identifier's hash.
    var hashedProviderName: String {
        Self.hashed(
            Self.prefix(kind) + Self.sanitized(identifier),
            identifier: identifier
        )
    }

    /// The strictest gateway's limit on a function name.
    static let providerNameLimit = 64

    private var kind: String {
        switch self {
        case .tool: "tool"
        case .program: "program"
        case .inference: "inference"
        case .agent: "agent"
        }
    }

    private var identifier: String {
        switch self {
        case .tool(let identifier): identifier.rawValue
        case .program(let identifier): identifier.rawValue
        case .inference(let identifier): identifier.rawValue
        case .agent(let identifier): identifier.rawValue
        }
    }

    private static func readable(kind: String, identifier: String) -> String {
        let name = prefix(kind) + sanitized(identifier)
        return name.count <= providerNameLimit ? name : hashed(name, identifier: identifier)
    }

    private static func prefix(_ kind: String) -> String {
        kind + "_"
    }

    private static func sanitized(_ identifier: String) -> String {
        String(identifier.unicodeScalars.map { scalar -> Character in
            switch scalar {
            case "a"..."z", "A"..."Z", "0"..."9", "_", "-": Character(scalar)
            default: "_"
            }
        })
    }

    /// `name` cut to leave room for `_` and eight hex digits of the
    /// identifier's FNV-1a hash.
    private static func hashed(_ name: String, identifier: String) -> String {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in identifier.utf8 {
            hash = (hash ^ UInt64(byte)) &* 0x100000001b3
        }
        let hexadecimal = String(hash, radix: 16)
        let digits = String(repeating: "0", count: max(0, 16 - hexadecimal.count)) + hexadecimal
        return String(name.prefix(providerNameLimit - 9)) + "_" + digits.prefix(8)
    }
}
