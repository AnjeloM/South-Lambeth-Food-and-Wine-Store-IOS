import Foundation

// MARK: - SetPrintOrderUiState

public struct SetPrintOrderUiState: Equatable {

    // MARK: List-selection mode

    /// All saved order lists.
    public var lists: [PrintOrderList]

    /// ID of the list currently marked as the default template.
    public var defaultListId: UUID?

    // MARK: Edit mode

    /// Non-nil when the user has opened a list for editing.
    /// This is a mutable working copy — not yet persisted.
    public var editingList: PrintOrderList?

    /// IDs of nodes whose children are currently visible.
    public var expandedNodeIds: Set<UUID>

    /// True when `editingList` has unsaved changes.
    public var isDirty: Bool

    // MARK: Async state

    public var isLoading: Bool
    public var isSaving: Bool

    public init(
        lists: [PrintOrderList] = [],
        defaultListId: UUID? = nil,
        editingList: PrintOrderList? = nil,
        expandedNodeIds: Set<UUID> = [],
        isDirty: Bool = false,
        isLoading: Bool = true,
        isSaving: Bool = false
    ) {
        self.lists = lists
        self.defaultListId = defaultListId
        self.editingList = editingList
        self.expandedNodeIds = expandedNodeIds
        self.isDirty = isDirty
        self.isLoading = isLoading
        self.isSaving = isSaving
    }
}
