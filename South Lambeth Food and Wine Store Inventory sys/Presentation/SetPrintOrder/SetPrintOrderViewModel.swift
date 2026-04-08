import Foundation
import SwiftUI
import Combine

// MARK: - SetPrintOrderViewModel

@MainActor
public final class SetPrintOrderViewModel: ObservableObject {

    // MARK: Published

    @Published public private(set) var state: SetPrintOrderUiState = SetPrintOrderUiState()
    @Published public private(set) var effect: SetPrintOrderUiEffect?

    // MARK: Dependencies

    private let repository: PrintOrderRepositoring

    // MARK: Init

    public init(repository: PrintOrderRepositoring) {
        self.repository = repository
        Task { @MainActor in loadStorage() }
    }

    // MARK: - Event Handler

    public func onEvent(_ event: SetPrintOrderUiEvent) {
        switch event {

        // MARK: Navigation

        case .onCloseTapped:
            if state.isDirty {
                // Discard unsaved changes and go back
                state.editingList = nil
                state.isDirty = false
            }
            emit(.navigateBack)

        case .onBackFromEdit:
            state.editingList = nil
            state.isDirty = false

        // MARK: List Selection

        case .onSelectListForEdit(let listId):
            guard let list = state.lists.first(where: { $0.id == listId }) else { return }
            state.editingList = list
            state.isDirty = false
            state.expandedNodeIds = []

        case .onSetDefault(let listId):
            var storage = repository.load()
            storage.defaultListId = listId
            repository.save(storage)
            state.defaultListId = listId
            emit(.showToast("Default updated"))

        // MARK: Expand / Collapse

        case .onToggleExpand(let nodeId):
            if state.expandedNodeIds.contains(nodeId) {
                state.expandedNodeIds.remove(nodeId)
            } else {
                state.expandedNodeIds.insert(nodeId)
            }

        // MARK: Reorder

        case .onReorderTopLevel(let from, let to):
            guard var list = state.editingList else { return }
            list.nodes.move(fromOffsets: from, toOffset: to)
            state.editingList = list
            state.isDirty = true

        case .onReorderChildren(let parentId, let from, let to):
            guard var list = state.editingList else { return }
            list.nodes = reorder(in: list.nodes, parentId: parentId, from: from, to: to)
            state.editingList = list
            state.isDirty = true

        // MARK: Save

        case .onSaveTapped:
            guard let editedList = state.editingList else { return }
            state.isSaving = true

            var storage = repository.load()
            if let idx = storage.lists.firstIndex(where: { $0.id == editedList.id }) {
                storage.lists[idx] = editedList
            } else {
                storage.lists.append(editedList)
            }
            repository.save(storage)

            state.lists = storage.lists
            state.isDirty = false
            state.isSaving = false
            emit(.showToast("Order saved"))
        }
    }

    // MARK: - Private Helpers

    private func loadStorage() {
        let storage = repository.load()
        state.lists = storage.lists
        state.defaultListId = storage.defaultListId
        state.isLoading = false
    }

    private func emit(_ newEffect: SetPrintOrderUiEffect) {
        effect = newEffect
        Task { @MainActor in
            await Task.yield()
            self.effect = nil
        }
    }

    /// Recursively walks `nodes`, finds the node with `parentId`, and applies the move.
    private func reorder(
        in nodes: [PrintOrderNode],
        parentId: UUID,
        from: IndexSet,
        to: Int
    ) -> [PrintOrderNode] {
        nodes.map { node in
            var updated = node
            if node.id == parentId {
                updated.children?.move(fromOffsets: from, toOffset: to)
            } else if updated.children != nil {
                updated.children = reorder(
                    in: updated.children!,
                    parentId: parentId,
                    from: from,
                    to: to
                )
            }
            return updated
        }
    }
}

