import Agentic
import Foundation
import Workspace

/// Evidence acquisition is a domain extension point, not a model-authored closure.
public protocol AssertionObservationProvider: Sendable {
    var kind: String { get }
    func observe(
        _ subject: Assertion.Subject,
        in context: ToolContext
    ) async -> AssertionObservation
}

public struct AssertionObservation: Sendable {
    public let exists: Bool?
    public let text: String?
    public let lineCount: Int?
    public let error: String?

    public init(
        exists: Bool? = nil,
        text: String? = nil,
        lineCount: Int? = nil,
        error: String? = nil
    ) {
        self.exists = exists
        self.text = text
        self.lineCount = lineCount
        self.error = error
    }
}

public struct LiteralTextAssertionProvider: AssertionObservationProvider {
    public let kind = "literal_text"

    public init() {}

    public func observe(
        _ subject: Assertion.Subject,
        in _: ToolContext
    ) async -> AssertionObservation {
        .init(
            exists: true,
            text: subject.value,
            lineCount: subject.value.components(separatedBy: "\n").count
        )
    }
}

/// All paths are resolved via Workspace's authority before any filesystem probe.
public struct WorkspaceFileAssertionProvider: AssertionObservationProvider {
    public let kind = "workspace_file"
    public let maximumReadBytes: Int

    public init(maximumReadBytes: Int = 1_048_576) {
        self.maximumReadBytes = max(1, maximumReadBytes)
    }

    public func observe(
        _ subject: Assertion.Subject,
        in context: ToolContext
    ) async -> AssertionObservation {
        do {
            guard let workspace = context.workspace else {
                return .init(error: "A workspace is required for file assertions")
            }
            let authorized = try workspace.authorize(
                subject.value,
                capability: .read
            ).authorizedPath
            let url = authorized.absoluteURL
            let attributes: [FileAttributeKey: Any]
            do {
                attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            } catch {
                let nsError = error as NSError
                if nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileReadNoSuchFileError {
                    return .init(exists: false)
                }
                return .init(error: "Unable to inspect authorized path: \(error)")
            }

            guard attributes[.type] as? FileAttributeType == .typeRegular else {
                return .init(exists: true, error: "The path is not a regular file")
            }
            guard let byteCount = attributes[.size] as? NSNumber,
                  byteCount.intValue <= maximumReadBytes else {
                return .init(exists: true, error: "File exceeds bounded assertion read limit")
            }
            let data = try Data(contentsOf: url)
            guard data.count <= maximumReadBytes,
                  let text = String(data: data, encoding: .utf8) else {
                return .init(exists: true, error: "File is oversized or not UTF-8 text")
            }
            return .init(
                exists: true,
                text: text,
                lineCount: text.components(separatedBy: "\n").count
            )
        } catch {
            return .init(error: "Workspace authorization or read failed: \(error)")
        }
    }
}
