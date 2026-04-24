public actor TodoManager {
    private var itemsStorage: [TodoItem]

    public init(
        items: [TodoItem] = []
    ) {
        self.itemsStorage = items
    }

    public func items() -> [TodoItem] {
        itemsStorage
    }

    public func replace(
        with items: [TodoItem]
    ) {
        itemsStorage = items
    }
}
