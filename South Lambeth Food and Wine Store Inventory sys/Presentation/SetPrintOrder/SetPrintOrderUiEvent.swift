import Foundation

// MARK: - SetPrintOrderUiEvent

public enum SetPrintOrderUiEvent {

    // MARK: Navigation

    /// User tapped the top-level back / close button.
    case onCloseTapped

    /// User tapped back while inside the hierarchy editor (returns to list-selection).
    case onBackFromEdit

    // MARK: List-selection screen

    /// User tapped a list row to open it in the hierarchy editor.
    case onSelectListForEdit(listId: UUID)

    /// User tapped "Set as Default" for a given list.
    case onSetDefault(listId: UUID)

    // MARK: Hierarchy editor

    /// User toggled expand / collapse on a non-leaf node.
    case onToggleExpand(nodeId: UUID)

    /// Drag-to-reorder on the top-level main-category array.
    case onReorderTopLevel(from: IndexSet, to: Int)

    /// Drag-to-reorder on the children of a specific parent node.
    case onReorderChildren(parentId: UUID, from: IndexSet, to: Int)

    /// User tapped Save to persist the current working copy.
    case onSaveTapped
}
