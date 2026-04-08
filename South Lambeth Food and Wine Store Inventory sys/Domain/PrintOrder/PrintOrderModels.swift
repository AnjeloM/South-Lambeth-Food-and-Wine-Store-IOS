import Foundation

// MARK: - PrintNodeLevel

public enum PrintNodeLevel: String, Codable, Equatable {
    case mainCategory
    case subcategory
    case group
    case item
}

// MARK: - PrintOrderNode

/// A node in the print-order hierarchy. Leaf nodes (level == .item) have no children.
public struct PrintOrderNode: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var level: PrintNodeLevel
    public var children: [PrintOrderNode]?
    public var quantity: Int?

    public var isLeaf: Bool {
        guard let children else { return true }
        return children.isEmpty
    }

    public init(
        id: UUID = UUID(),
        name: String,
        level: PrintNodeLevel,
        children: [PrintOrderNode]? = nil,
        quantity: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.level = level
        self.children = children
        self.quantity = quantity
    }

    /// Flat list of all leaf (.item) descendants, depth-first.
    public func flatLeaves() -> [PrintOrderNode] {
        if isLeaf { return [self] }
        return (children ?? []).flatMap { $0.flatLeaves() }
    }
}

// MARK: - PrintOrderList

public struct PrintOrderList: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var nodes: [PrintOrderNode]     // top-level main categories
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        nodes: [PrintOrderNode],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.nodes = nodes
        self.createdAt = createdAt
    }

    /// Total count of leaf items across the entire hierarchy.
    public var leafCount: Int {
        nodes.reduce(0) { $0 + $1.flatLeaves().count }
    }

    /// All leaf nodes flattened in depth-first order.
    public func allLeaves() -> [PrintOrderNode] {
        nodes.flatMap { $0.flatLeaves() }
    }
}

// MARK: - PrintOrderStorage

/// Root persistence envelope: holds all order lists and the selected default.
public struct PrintOrderStorage: Codable, Equatable {
    public var lists: [PrintOrderList]
    public var defaultListId: UUID?

    /// Returns the list marked as default, or the first list if none is marked.
    public var defaultList: PrintOrderList? {
        if let id = defaultListId, let match = lists.first(where: { $0.id == id }) {
            return match
        }
        return lists.first
    }

    public init(lists: [PrintOrderList] = [], defaultListId: UUID? = nil) {
        self.lists = lists
        self.defaultListId = defaultListId
    }
}
