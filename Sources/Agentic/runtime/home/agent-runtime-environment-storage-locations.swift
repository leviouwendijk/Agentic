import Foundation

public extension AgentRuntimeEnvironment {
    func sessionsdir() -> URL? {
        switch sessionStorageMode {
        case .global_home:
            return home.layout.sessionsdir

        case .project_local:
            return projectDiscovery?.agenticdir
                .appendingPathComponent(
                    "sessions",
                    isDirectory: true
                )

        case .custom(let rootURL):
            return rootURL.appendingPathComponent(
                "sessions",
                isDirectory: true
            )

        case .ephemeral:
            return nil
        }
    }

    func transcriptsdir() -> URL? {
        switch sessionStorageMode {
        case .global_home:
            return home.layout.transcriptsdir

        case .project_local:
            return projectDiscovery?.agenticdir
                .appendingPathComponent(
                    "transcripts",
                    isDirectory: true
                )

        case .custom(let rootURL):
            return rootURL.appendingPathComponent(
                "transcripts",
                isDirectory: true
            )

        case .ephemeral:
            return nil
        }
    }

    func approvalsdir() -> URL? {
        switch sessionStorageMode {
        case .global_home:
            return home.layout.approvalsdir

        case .project_local:
            return projectDiscovery?.agenticdir
                .appendingPathComponent(
                    "approvals",
                    isDirectory: true
                )

        case .custom(let rootURL):
            return rootURL.appendingPathComponent(
                "approvals",
                isDirectory: true
            )

        case .ephemeral:
            return nil
        }
    }

    func artifactsdir() -> URL? {
        switch sessionStorageMode {
        case .global_home:
            return home.layout.artifactsdir

        case .project_local:
            return projectDiscovery?.agenticdir
                .appendingPathComponent(
                    "artifacts",
                    isDirectory: true
                )

        case .custom(let rootURL):
            return rootURL.appendingPathComponent(
                "artifacts",
                isDirectory: true
            )

        case .ephemeral:
            return nil
        }
    }

    func tasksdir() -> URL? {
        switch sessionStorageMode {
        case .global_home:
            return home.layout.tasksdir

        case .project_local:
            return projectDiscovery?.agenticdir
                .appendingPathComponent(
                    "tasks",
                    isDirectory: true
                )

        case .custom(let rootURL):
            return rootURL.appendingPathComponent(
                "tasks",
                isDirectory: true
            )

        case .ephemeral:
            return nil
        }
    }
}
