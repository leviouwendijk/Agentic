import AgenticLinkerSupport

#if canImport(MachO)
import MachO
#endif

private typealias InstallationFactory =
    @convention(c) () -> UnsafeMutableRawPointer

func _agentic_domain_installation(
    namespace: String?
) -> DomainInstallation {
    .init(
        declarations: _agentic_installables(
            namespace: namespace
        )
    )
}

private func _agentic_installables(
    namespace: String?
) -> [any DomainInstallable.Type] {
#if canImport(MachO)
    var declarations = [any DomainInstallable.Type]()
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

        declarations += _agentic_installables(
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

    return _agentic_installables(
        bytes: start,
        byteCount: stopAddress - startAddress,
        namespace: namespace
    )
#else
    _ = namespace
    return []
#endif
}

private func _agentic_installables(
    bytes: UnsafeRawPointer,
    byteCount: Int,
    namespace: String?
) -> [any DomainInstallable.Type] {
    let entryStride = MemoryLayout<InstallationFactory>.stride

    guard
        entryStride > 0,
        byteCount >= 0,
        byteCount % entryStride == 0
    else {
        return []
    }

    var declarations = [any DomainInstallable.Type]()

    for offset in stride(
        from: 0,
        to: byteCount,
        by: entryStride
    ) {
        let factory = bytes
            .advanced(by: offset)
            .load(as: InstallationFactory.self)
        let opaque = factory()
        let entry = Unmanaged<
            CatalogLinkerEntryBox
        >.fromOpaque(
            opaque
        ).takeRetainedValue()

        guard
            entry.namespace == namespace,
            let installable = entry.installable
        else {
            continue
        }

        declarations.append(
            installable
        )
    }

    return declarations
}
