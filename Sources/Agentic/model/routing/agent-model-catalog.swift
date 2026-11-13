public extension AgentModel {
    struct Catalog: Sendable {
        private let storage: [ID: AgentModel]

        public init(
            models: [AgentModel] = []
        ) throws {
            var storage: [ID: AgentModel] = [:]

            for model in models {
                guard storage[model.id] == nil else {
                    throw Error.duplicate(
                        model.id
                    )
                }

                storage[model.id] = model
            }

            self.storage = storage
        }

        public var count: Int {
            storage.count
        }

        public func model(
            _ id: ID
        ) -> AgentModel? {
            storage[id]
        }

        public subscript(
            _ id: ID
        ) -> AgentModel? {
            storage[id]
        }
    }
}

public extension AgentModel.Catalog {
    enum Error:
        Swift.Error,
        Sendable,
        Hashable
    {
        case duplicate(AgentModel.ID)
    }
}
