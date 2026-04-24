enum FlowTestResult {
    case passed(
        name: String,
        diagnostics: [String]
    )
    case failed(
        name: String,
        diagnostics: [String]
    )

    var name: String {
        switch self {
        case .passed(let name, _),
             .failed(let name, _):
            return name
        }
    }

    var diagnostics: [String] {
        switch self {
        case .passed(_, let diagnostics),
             .failed(_, let diagnostics):
            return diagnostics
        }
    }

    var isFailure: Bool {
        switch self {
        case .passed:
            return false

        case .failed:
            return true
        }
    }
}
