public struct DomainInstallation {
    public typealias Installer = (any Sink) -> Void

    public protocol Sink: AnyObject {
        func install<T: Tool>(
            _ tool: T,
            modelContract: ToolModelContract?
        )

        func install<P: Program>(
            _ program: P,
            realization: ProgramRealization<P>?
        )

        func install(
            _ agent: AgentDefinition
        )
    }

    let installers: [Installer]

    init(
        installers: [Installer]
    ) {
        self.installers = installers
    }

    public func install(
        into sink: any Sink
    ) {
        for installer in installers {
            installer(
                sink
            )
        }
    }
}

public extension DomainInstallation.Sink {
    func install<T: Tool>(
        _ tool: T
    ) {
        install(
            tool,
            modelContract: nil
        )
    }

    func install<P: Program>(
        _ program: P
    ) {
        install(
            program,
            realization: nil
        )
    }
}
