import SwiftUI

// MARK: - SetPrintOrderScreen

/// Pure SwiftUI view. Receives state + onEvent — zero VM reference, zero business logic.
public struct SetPrintOrderScreen: View {

    public let state: SetPrintOrderUiState
    public let onEvent: (SetPrintOrderUiEvent) -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var toastMessage: String? = nil

    public init(state: SetPrintOrderUiState, onEvent: @escaping (SetPrintOrderUiEvent) -> Void) {
        self.state = state
        self.onEvent = onEvent
    }

    public var body: some View {
        Group {
            if state.isLoading {
                loadingView
            } else if state.editingList != nil {
                hierarchyEditorView
            } else {
                orderListsView
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .overlay(alignment: .bottom) { toastOverlay }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                if state.editingList != nil {
                    onEvent(.onBackFromEdit)
                } else {
                    onEvent(.onCloseTapped)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text(state.editingList != nil ? "Order Lists" : "Close")
                        .font(.system(size: 16))
                }
                .foregroundStyle(AppTheme.Colors.accent(scheme))
            }
        }

        ToolbarItem(placement: .principal) {
            Text(state.editingList?.name ?? "Set Print Order")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
        }

        if state.editingList != nil {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    onEvent(.onSaveTapped)
                } label: {
                    if state.isSaving {
                        ProgressView()
                            .tint(AppTheme.Colors.accent(scheme))
                    } else {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(state.isDirty
                                ? AppTheme.Colors.accent(scheme)
                                : AppTheme.Colors.secondaryText(scheme))
                    }
                }
                .disabled(!state.isDirty || state.isSaving)
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(AppTheme.Colors.accent(scheme))
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.background(scheme).ignoresSafeArea())
    }

    // MARK: - Order Lists View

    private var orderListsView: some View {
        List {
            Section {
                ForEach(state.lists) { list in
                    OrderListRow(
                        list: list,
                        isDefault: list.id == state.defaultListId,
                        onEdit: { onEvent(.onSelectListForEdit(listId: list.id)) },
                        onSetDefault: { onEvent(.onSetDefault(listId: list.id)) }
                    )
                }
            } header: {
                Text("SAVED ORDER LISTS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                    .textCase(nil)
            } footer: {
                Text("The default list is used as the template when printing inventory reports.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.Colors.background(scheme).ignoresSafeArea())
    }

    // MARK: - Hierarchy Editor

    private var hierarchyEditorView: some View {
        List {
            if let list = state.editingList {
                Section {
                    ForEach(list.nodes) { mainNode in
                        mainCategoryRows(mainNode)
                    }
                    .onMove { from, to in
                        onEvent(.onReorderTopLevel(from: from, to: to))
                    }
                } header: {
                    Text("CATEGORIES")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                        .textCase(nil)
                }

                // Dirty-state hint
                if state.isDirty {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(AppTheme.Colors.accent(scheme))
                            Text("You have unsaved changes. Tap Save to keep them.")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.Colors.background(scheme).ignoresSafeArea())
        .environment(\.editMode, .constant(.active))
    }

    // MARK: - Row Builders

    /// Emits the main-category row plus any visible subcategory rows beneath it.
    @ViewBuilder
    private func mainCategoryRows(_ node: PrintOrderNode) -> some View {
        // Main category header row
        HierarchyNodeRow(
            node: node,
            depth: 0,
            isExpanded: state.expandedNodeIds.contains(node.id),
            onToggle: { onEvent(.onToggleExpand(nodeId: node.id)) }
        )

        // Subcategories (only when expanded)
        if state.expandedNodeIds.contains(node.id), let children = node.children, !children.isEmpty {
            ForEach(children) { subcat in
                subcategoryRows(subcat, parentId: node.id)
            }
            .onMove { from, to in
                onEvent(.onReorderChildren(parentId: node.id, from: from, to: to))
            }
        }
    }

    /// Emits the subcategory row plus any visible group rows beneath it.
    @ViewBuilder
    private func subcategoryRows(_ node: PrintOrderNode, parentId: UUID) -> some View {
        HierarchyNodeRow(
            node: node,
            depth: 1,
            isExpanded: state.expandedNodeIds.contains(node.id),
            onToggle: { onEvent(.onToggleExpand(nodeId: node.id)) }
        )

        if state.expandedNodeIds.contains(node.id), let children = node.children, !children.isEmpty {
            ForEach(children) { groupNode in
                groupRows(groupNode, parentId: node.id)
            }
            .onMove { from, to in
                onEvent(.onReorderChildren(parentId: node.id, from: from, to: to))
            }
        }
    }

    /// Emits the group row plus any visible leaf-item rows beneath it.
    @ViewBuilder
    private func groupRows(_ node: PrintOrderNode, parentId: UUID) -> some View {
        HierarchyNodeRow(
            node: node,
            depth: 2,
            isExpanded: state.expandedNodeIds.contains(node.id),
            onToggle: { onEvent(.onToggleExpand(nodeId: node.id)) }
        )

        if state.expandedNodeIds.contains(node.id), let items = node.children, !items.isEmpty {
            ForEach(items) { item in
                HierarchyNodeRow(
                    node: item,
                    depth: 3,
                    isExpanded: false,
                    onToggle: {}   // leaf — no toggle
                )
            }
            .onMove { from, to in
                onEvent(.onReorderChildren(parentId: node.id, from: from, to: to))
            }
        }
    }

    // MARK: - Toast Overlay

    @ViewBuilder
    private var toastOverlay: some View {
        if let msg = toastMessage {
            Text(msg)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - HierarchyNodeRow

private struct HierarchyNodeRow: View {

    let node: PrintOrderNode
    let depth: Int
    let isExpanded: Bool
    let onToggle: () -> Void

    @Environment(\.colorScheme) private var scheme

    private var indentPadding: CGFloat { CGFloat(depth) * 20 }

    var body: some View {
        HStack(spacing: 10) {

            // Indent spacer
            if depth > 0 {
                Spacer().frame(width: indentPadding)
            }

            // Expand / collapse chevron (non-leaf only)
            if !node.isLeaf {
                Button(action: onToggle) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.accent(scheme))
                        .frame(width: 18, height: 18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                // Leaf bullet
                Circle()
                    .fill(AppTheme.Colors.secondaryText(scheme).opacity(0.4))
                    .frame(width: 5, height: 5)
                    .padding(.leading, 7)
            }

            // Node name
            Text(node.name)
                .font(labelFont)
                .foregroundStyle(labelColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)

            // Quantity badge (leaf items only)
            if node.isLeaf, let qty = node.quantity {
                Text("×\(qty)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.Colors.surfaceContainer(scheme))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, rowVerticalPadding)
        .listRowBackground(rowBackground)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    // MARK: Styling helpers

    private var labelFont: Font {
        switch depth {
        case 0:  return .system(size: 15, weight: .semibold)
        case 1:  return .system(size: 14, weight: .medium)
        case 2:  return .system(size: 13, weight: .regular)
        default: return .system(size: 12, weight: .regular)
        }
    }

    private var labelColor: Color {
        switch depth {
        case 0:  return AppTheme.Colors.primaryText(scheme)
        case 1:  return AppTheme.Colors.primaryText(scheme)
        case 2:  return AppTheme.Colors.secondaryText(scheme)
        default: return AppTheme.Colors.secondaryText(scheme).opacity(0.8)
        }
    }

    private var rowVerticalPadding: CGFloat {
        depth == 0 ? 12 : 8
    }

    @ViewBuilder
    private var rowBackground: some View {
        if depth == 0 {
            AppTheme.Colors.surfaceContainer(scheme)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Color.clear
        }
    }
}

// MARK: - OrderListRow

private struct OrderListRow: View {

    let list: PrintOrderList
    let isDefault: Bool
    let onEdit: () -> Void
    let onSetDefault: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(list.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.primaryText(scheme))

                        if isDefault {
                            Label("Default", systemImage: "checkmark.seal.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.buttonText(scheme))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.Colors.accent(scheme))
                                .clipShape(Capsule())
                        }
                    }

                    Text("\(list.leafCount) items · Created \(list.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                }

                Spacer()

                Button("Edit", action: onEdit)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.accent(scheme))
            }

            if !isDefault {
                Button(action: onSetDefault) {
                    Label("Set as Default", systemImage: "checkmark.seal")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.accent(scheme))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Previews

#Preview("Order Lists - Light") {
    NavigationStack {
        SetPrintOrderScreen(
            state: {
                var s = SetPrintOrderUiState()
                s.lists = [DefaultPrintOrderData.defaultList]
                s.defaultListId = DefaultPrintOrderData.defaultList.id
                s.isLoading = false
                return s
            }(),
            onEvent: { _ in }
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Order Lists - Dark") {
    NavigationStack {
        SetPrintOrderScreen(
            state: {
                var s = SetPrintOrderUiState()
                s.lists = [DefaultPrintOrderData.defaultList]
                s.defaultListId = DefaultPrintOrderData.defaultList.id
                s.isLoading = false
                return s
            }(),
            onEvent: { _ in }
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Hierarchy Editor - Light") {
    NavigationStack {
        SetPrintOrderScreen(
            state: {
                var s = SetPrintOrderUiState()
                let list = DefaultPrintOrderData.defaultList
                s.lists = [list]
                s.defaultListId = list.id
                s.editingList = list
                s.expandedNodeIds = [list.nodes.first!.id]
                s.isLoading = false
                s.isDirty = true
                return s
            }(),
            onEvent: { _ in }
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Hierarchy Editor - Dark") {
    NavigationStack {
        SetPrintOrderScreen(
            state: {
                var s = SetPrintOrderUiState()
                let list = DefaultPrintOrderData.defaultList
                s.lists = [list]
                s.defaultListId = list.id
                s.editingList = list
                s.expandedNodeIds = Set(list.nodes.prefix(3).map { $0.id })
                s.isLoading = false
                return s
            }(),
            onEvent: { _ in }
        )
    }
    .preferredColorScheme(.dark)
}
