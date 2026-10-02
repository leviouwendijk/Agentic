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
        installers: _agentic_installers(
            namespace: namespace
        )
    )
}

private func _agentic_installers(
    namespace: String?
) -> [DomainInstallation.Installer] {
#if canImport(MachO)
    var installers = [DomainInstallation.Installer]()
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

        installers += _agentic_installers(
            bytes: UnsafeRawPointer(section),
            byteCount: Int(byteCount),
            namespace: namespace
        )
    }

    return installers
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

    return _agentic_installers(
        bytes: start,
        byteCount: stopAddress - startAddress,
        namespace: namespace
    )
#else
    _ = namespace
    return []
#endif
}

private func _agentic_installers(
    bytes: UnsafeRawPointer,
    byteCount: Int,
    namespace: String?
) -> [DomainInstallation.Installer] {
    let entryStride = MemoryLayout<InstallationFactory>.stride

    guard
        entryStride > 0,
        byteCount >= 0,
        byteCount % entryStride == 0
    else {
        return []
    }

    var installers = [DomainInstallation.Installer]()

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
            let installer = entry.installer
        else {
            continue
        }

        installers.append(
            installer
        )
    }

    return installers
}
