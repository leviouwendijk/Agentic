public struct ScanPathsToolInput: Sendable, Codable, Hashable {
    public let path: String?
    public let excludes: [String]
    public let includeFiles: Bool
    public let includeDirectories: Bool
    public let recursive: Bool
    public let includeHidden: Bool
    public let followSymlinks: Bool
    public let maxEntries: Int?

    public init(
        path: String? = nil,
        excludes: [String] = [],
        includeFiles: Bool = true,
        includeDirectories: Bool = true,
        recursive: Bool = false,
        includeHidden: Bool = false,
        followSymlinks: Bool = false,
        maxEntries: Int? = nil
    ) {
        self.path = path
        self.excludes = excludes
        self.includeFiles = includeFiles
        self.includeDirectories = includeDirectories
        self.recursive = recursive
        self.includeHidden = includeHidden
        self.followSymlinks = followSymlinks
        self.maxEntries = maxEntries
    }
}
