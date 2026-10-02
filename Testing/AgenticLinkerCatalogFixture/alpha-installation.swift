import Agentic

extension LinkerCatalogFixture.Tools.Alpha:
    DomainInstallable
{
    public static func install(
        into sink: any DomainInstallation.Sink
    ) {
        sink.install(
            Self()
        )
    }
}
