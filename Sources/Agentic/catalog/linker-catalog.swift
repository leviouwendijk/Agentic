#if canImport(MachO)
import MachO
#endif

private final class CatalogLinkerEntryBox {
    let namespace: String
    let declaration: Catalog.Declaration

    init(
        namespace: String,
        declaration: Catalog.Declaration
    ) {
        self.namespace = namespace
        self.declaration = declaration
    }
}

public func _agentic_catalog_entry(
    namespace: String,
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
    namespace: String
) -> [Catalog.Declaration] {
#if canImport(MachO)
    typealias Factory =
        @convention(c) () -> UnsafeMutableRawPointer

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

        let entryStride = MemoryLayout<Factory>.stride

        guard
            entryStride > 0,
            byteCount % UInt(entryStride) == 0
        else {
            continue
        }

        let bytes = UnsafeRawPointer(
            section
        )

        for offset in stride(
            from: 0,
            to: Int(byteCount),
            by: entryStride
        ) {
            let factory = bytes
                .advanced(by: offset)
                .load(as: Factory.self)
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
    }

    return declarations
#else
    _ = namespace
    return []
#endif
}
