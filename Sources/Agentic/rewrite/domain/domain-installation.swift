public protocol DomainInstallable {
    static func install(
        into sink: any DomainInstallation.Sink
    )
}

public struct DomainInstallation {
    public protocol Sink: AnyObject {
        func install<T: Tool>(
            _ tool: T,
            modelContract: AgentToolModelContract?,
            execution: AgentToolExecutionContract
        )

        func install<P: Program>(
            _ program: P,
            realization: ProgramRealization<P>?
        )

        func install(
            _ agent: AgentDefinition
        )
    }

    let declarations: [any DomainInstallable.Type]

    init(
        declarations: [any DomainInstallable.Type]
    ) {
        self.declarations = declarations
    }

    public func install(
        into sink: any Sink
    ) {
        for declaration in declarations {
            declaration.install(
                into: sink
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
            modelContract: nil,
            execution: .fixed
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
