import Foundation
import Path
import Writers
import FileTypes

public struct FileEditor: Sendable {
    public let workspace: AgentWorkspace

    public init(
        workspace: AgentWorkspace
    ) {
        self.workspace = workspace
    }

    @discardableResult
    public func write(
        _ text: String,
        to path: ScopedPath,
        encoding: String.Encoding = .utf8,
        options: SafeWriteOptions = .overwrite
    ) throws -> StandardEditResult {
        try StandardWriter(
            workspace.absoluteURL(for: path)
        ).editor.edit(
            .replaceEntireFile(with: text),
            encoding: encoding,
            options: options
        )
    }

    @discardableResult
    public func write(
        _ text: String,
        to path: StandardPath,
        encoding: String.Encoding = .utf8,
        options: SafeWriteOptions = .overwrite
    ) throws -> StandardEditResult {
        try write(
            text,
            to: workspace.resolve(path),
            encoding: encoding,
            options: options
        )
    }

    @discardableResult
    public func write(
        _ text: String,
        to rawPath: String,
        filetype: AnyFileType? = nil,
        encoding: String.Encoding = .utf8,
        options: SafeWriteOptions = .overwrite
    ) throws -> StandardEditResult {
        try write(
            text,
            to: workspace.resolve(
                rawPath,
                filetype: filetype
            ),
            encoding: encoding,
            options: options
        )
    }

    public func previewWrite(
        _ text: String,
        to path: ScopedPath,
        encoding: String.Encoding = .utf8
    ) throws -> StandardEditResult {
        try StandardWriter(
            workspace.absoluteURL(for: path)
        ).editor.preview(
            .replaceEntireFile(with: text),
            encoding: encoding
        )
    }

    public func previewWrite(
        _ text: String,
        to path: StandardPath,
        encoding: String.Encoding = .utf8
    ) throws -> StandardEditResult {
        try previewWrite(
            text,
            to: workspace.resolve(path),
            encoding: encoding
        )
    }

    public func previewWrite(
        _ text: String,
        to rawPath: String,
        filetype: AnyFileType? = nil,
        encoding: String.Encoding = .utf8
    ) throws -> StandardEditResult {
        try previewWrite(
            text,
            to: workspace.resolve(
                rawPath,
                filetype: filetype
            ),
            encoding: encoding
        )
    }

    @discardableResult
    public func edit(
        _ operation: StandardEditOperation,
        at path: ScopedPath,
        encoding: String.Encoding = .utf8,
        options: SafeWriteOptions = .overwrite
    ) throws -> StandardEditResult {
        try StandardWriter(
            workspace.absoluteURL(for: path)
        ).editor.edit(
            operation,
            encoding: encoding,
            options: options
        )
    }

    @discardableResult
    public func edit(
        _ operation: StandardEditOperation,
        at path: StandardPath,
        encoding: String.Encoding = .utf8,
        options: SafeWriteOptions = .overwrite
    ) throws -> StandardEditResult {
        try edit(
            operation,
            at: workspace.resolve(path),
            encoding: encoding,
            options: options
        )
    }

    @discardableResult
    public func edit(
        _ operation: StandardEditOperation,
        at rawPath: String,
        filetype: AnyFileType? = nil,
        encoding: String.Encoding = .utf8,
        options: SafeWriteOptions = .overwrite
    ) throws -> StandardEditResult {
        try edit(
            operation,
            at: workspace.resolve(
                rawPath,
                filetype: filetype
            ),
            encoding: encoding,
            options: options
        )
    }

    @discardableResult
    public func edit(
        _ operations: [StandardEditOperation],
        at path: ScopedPath,
        encoding: String.Encoding = .utf8,
        options: SafeWriteOptions = .overwrite
    ) throws -> StandardEditResult {
        try StandardWriter(
            workspace.absoluteURL(for: path)
        ).editor.edit(
            operations,
            encoding: encoding,
            options: options
        )
    }

    @discardableResult
    public func edit(
        _ operations: [StandardEditOperation],
        at path: StandardPath,
        encoding: String.Encoding = .utf8,
        options: SafeWriteOptions = .overwrite
    ) throws -> StandardEditResult {
        try edit(
            operations,
            at: workspace.resolve(path),
            encoding: encoding,
            options: options
        )
    }

    @discardableResult
    public func edit(
        _ operations: [StandardEditOperation],
        at rawPath: String,
        filetype: AnyFileType? = nil,
        encoding: String.Encoding = .utf8,
        options: SafeWriteOptions = .overwrite
    ) throws -> StandardEditResult {
        try edit(
            operations,
            at: workspace.resolve(
                rawPath,
                filetype: filetype
            ),
            encoding: encoding,
            options: options
        )
    }

    public func previewEdit(
        _ operation: StandardEditOperation,
        at path: ScopedPath,
        encoding: String.Encoding = .utf8
    ) throws -> StandardEditResult {
        try StandardWriter(
            workspace.absoluteURL(for: path)
        ).editor.preview(
            operation,
            encoding: encoding
        )
    }

    public func previewEdit(
        _ operation: StandardEditOperation,
        at path: StandardPath,
        encoding: String.Encoding = .utf8
    ) throws -> StandardEditResult {
        try previewEdit(
            operation,
            at: workspace.resolve(path),
            encoding: encoding
        )
    }

    public func previewEdit(
        _ operation: StandardEditOperation,
        at rawPath: String,
        filetype: AnyFileType? = nil,
        encoding: String.Encoding = .utf8
    ) throws -> StandardEditResult {
        try previewEdit(
            operation,
            at: workspace.resolve(
                rawPath,
                filetype: filetype
            ),
            encoding: encoding
        )
    }

    public func previewEdit(
        _ operations: [StandardEditOperation],
        at path: ScopedPath,
        encoding: String.Encoding = .utf8
    ) throws -> StandardEditResult {
        try StandardWriter(
            workspace.absoluteURL(for: path)
        ).editor.preview(
            operations,
            encoding: encoding
        )
    }

    public func previewEdit(
        _ operations: [StandardEditOperation],
        at path: StandardPath,
        encoding: String.Encoding = .utf8
    ) throws -> StandardEditResult {
        try previewEdit(
            operations,
            at: workspace.resolve(path),
            encoding: encoding
        )
    }

    public func previewEdit(
        _ operations: [StandardEditOperation],
        at rawPath: String,
        filetype: AnyFileType? = nil,
        encoding: String.Encoding = .utf8
    ) throws -> StandardEditResult {
        try previewEdit(
            operations,
            at: workspace.resolve(
                rawPath,
                filetype: filetype
            ),
            encoding: encoding
        )
    }
}
