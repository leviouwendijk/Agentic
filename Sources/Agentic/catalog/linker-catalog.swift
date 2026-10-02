import AgenticLinkerSupport

#if canImport(MachO)
import MachO
#endif

private typealias CatalogFactory =
    @convention(c) () -> UnsafeMutableRawPointer

private final class CatalogLinkerEntryBox {
    let namespace: String?
    let declaration: Catalog.Declaration

    init(
        namespace: String?,
        declaration: Catalog.Declaration
    ) {
        self.namespace = namespace
        self.declaration = declaration
    }
}

public func _agentic_catalog_entry(
    namespace: String?,
    declaration: Catalog.Declaration
) -> UnsafeMutableRawPointer {
    Unmanaged.passRetained(
        CatalogLinkerEntryBox(
            namespace: namespace,
            declaration: declaration
        )
    ).toOpaque()
}

func _agentic_catalog_declarations(
    namespace: String?
) -> [Catalog.Declaration] {
#if canImport(MachO)
    var declarations = [Catalog.Declaration]()
    let imageCount = _dyld_image_count()

    for imageIndex in 0 ..< imageCount {
        guard let header = _dyld_get_image_header(
            imageIndex
        ) else {
            continue
        }

        guard
            header.pointee.magic == MH_MAGIC_64
                || header.pointee.magic == MH_CIGAM_64
        else {
            continue
        }

        let header64 = UnsafeRawPointer(
            header
        ).assumingMemoryBound(
            to: mach_header_64.self
        )

        var byteCount: UInt = 0

        guard let section = getsectiondata(
            header64,
            "__DATA",
            "__agentic",
            &byteCount
        ) else {
            continue
        }

        declarations += _agentic_catalog_declarations(
            bytes: UnsafeRawPointer(section),
            byteCount: Int(byteCount),
            namespace: namespace
        )
    }

    return declarations
#elseif objectFormat(ELF)
    guard
        let start = agentic_catalog_section_start(),
        let stop = agentic_catalog_section_stop()
    else {
        return []
    }

    let startAddress = Int(
        bitPattern: start
    )
    let stopAddress = Int(
        bitPattern: stop
    )

    guard stopAddress >= startAddress else {
        return []
    }

    return _agentic_catalog_declarations(
        bytes: start,
        byteCount: stopAddress - startAddress,
        namespace: namespace
    )
#else
    _ = namespace
    return []
#endif
}

private func _agentic_catalog_declarations(
    bytes: UnsafeRawPointer,
    byteCount: Int,
    namespace: String?
) -> [Catalog.Declaration] {
    let entryStride = MemoryLayout<CatalogFactory>.stride

    guard
        entryStride > 0,
        byteCount >= 0,
        byteCount % entryStride == 0
    else {
        return []
    }

    var declarations = [Catalog.Declaration]()

    for offset in stride(
        from: 0,
        to: byteCount,
        by: entryStride
    ) {
        let factory = bytes
            .advanced(by: offset)
            .load(as: CatalogFactory.self)
        let opaque = factory()
        let entry = Unmanaged<
            CatalogLinkerEntryBox
        >.fromOpaque(
            opaque
        ).takeRetainedValue()

        guard entry.namespace == namespace else {
            continue
        }

        declarations.append(
            entry.declaration
        )
    }

    return declarations
}
