import SwiftUI

// MARK: - Drawer Item Definition

private struct DrawerItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let action: () -> Void
}

// MARK: - AppDrawer

/// Full-screen side drawer that slides in from the left.
///
/// Usage:
/// ```swift
/// AppDrawer(isOpen: $isDrawerOpen, onLogout: { onEvent(.onSignOutTapped) })
/// ```
public struct AppDrawer: View {

    @Binding public var isOpen: Bool
    public let onLogout: () -> Void
    /// Called when the user taps "Set Print Order" — wires through HomeViewModel/HomeEffect.
    public let onSetPrintOrderTapped: () -> Void
    /// The default print order list; used by PrintSheetView for real data.
    public let defaultPrintList: PrintOrderList?

    public init(
        isOpen: Binding<Bool>,
        onLogout: @escaping () -> Void,
        onSetPrintOrderTapped: @escaping () -> Void = {},
        defaultPrintList: PrintOrderList? = nil
    ) {
        self._isOpen = isOpen
        self.onLogout = onLogout
        self.onSetPrintOrderTapped = onSetPrintOrderTapped
        self.defaultPrintList = defaultPrintList
    }

    @Environment(\.colorScheme) private var scheme

    @State private var showPrintSheet = false

    private let drawerWidth: CGFloat = 300

    public var body: some View {
        ZStack(alignment: .leading) {

            // MARK: Backdrop — tap to dismiss
            if isOpen {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture { close() }
                    .transition(.opacity)
            }

            // MARK: Drawer panel
            if isOpen {
                drawerPanel
                    .frame(width: drawerWidth)
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: isOpen)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        // MARK: Sheets
        .sheet(isPresented: $showPrintSheet) {
            PrintSheetView(printList: defaultPrintList)
        }
    }

    // MARK: - Drawer Panel

    private var drawerPanel: some View {
        VStack(spacing: 0) {

            // MARK: Profile Section
            profileSection

            Divider()
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

            // MARK: Menu Items
            ScrollView(showsIndicators: false) {
                VStack(spacing: 4) {
                    // Standard nav items
                    ForEach(menuItems) { item in
                        drawerRow(item: item)
                    }

                    Divider()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)

                    // Set Print Order — navigates to full-screen editor via HomeViewModel
                    drawerRow(item: DrawerItem(
                        icon: "arrow.up.arrow.down.circle.fill",
                        label: "Set Print Order",
                        action: { onSetPrintOrderTapped() }
                    ))

                    // Print — opens print preview sheet
                    drawerRow(item: DrawerItem(
                        icon: "printer.fill",
                        label: "Print",
                        action: { showPrintSheet = true }
                    ))
                }
                .padding(.top, 8)
                .padding(.bottom, 12)
            }

            Spacer()

            // MARK: Logout — pinned to bottom
            Divider()
                .padding(.horizontal, 20)

            logoutRow
                .padding(.bottom, 32)
        }
        .background(AppTheme.Colors.surface(scheme).ignoresSafeArea())
        .shadow(color: .black.opacity(0.18), radius: 16, x: 4, y: 0)
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        HStack(spacing: 14) {
            Image("ProfilePic")
                .resizable()
                .scaledToFill()
                .frame(width: 54, height: 54)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(AppTheme.Colors.fieldBorderVariant(scheme), lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text("Store Manager")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                Text("South Lambeth Store")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            }

            Spacer()

            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                    .frame(width: 32, height: 32)
                    .background(AppTheme.Colors.surfaceContainer(scheme))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

    // MARK: - Menu Row

    @ViewBuilder
    private func drawerRow(item: DrawerItem) -> some View {
        Button {
            close()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                item.action()
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: item.icon)
                    .font(.system(size: 17))
                    .foregroundStyle(AppTheme.Colors.accent(scheme))
                    .frame(width: 28)

                Text(item.label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme).opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    // MARK: - Logout Row

    private var logoutRow: some View {
        Button {
            close()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                onLogout()
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 17))
                    .foregroundStyle(AppTheme.Colors.error(scheme))
                    .frame(width: 28)

                Text("Logout")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.error(scheme))

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    // MARK: - Menu Items

    private var menuItems: [DrawerItem] {
        [
            DrawerItem(icon: "person.fill",            label: "Profile",            action: {}),
            DrawerItem(icon: "chart.bar.fill",         label: "Report",             action: {}),
            DrawerItem(icon: "clock.fill",             label: "TimeSheet",          action: {}),
            DrawerItem(icon: "clock.arrow.circlepath", label: "History",            action: {}),
            DrawerItem(icon: "doc.text.fill",          label: "Terms & Conditions", action: {}),
        ]
    }

    // MARK: - Helpers

    private func close() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
            isOpen = false
        }
    }
}

// MARK: - Print Sheet

private struct PrintSheetView: View {

    /// The default order list. When nil, falls back to sample data.
    let printList: PrintOrderList?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    /// Source nodes — real list or fallback.
    private var nodes: [PrintOrderNode] {
        printList?.nodes ?? fallbackNodes
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: Print Preview
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // Report header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SOUTH LAMBETH")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                            Text("Food & Wine Store — Print Order")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                            Text(Date().formatted(date: .long, time: .shortened))
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(AppTheme.Colors.surfaceContainer(scheme))

                        Divider()

                        // Hierarchical rows
                        ForEach(nodes) { node in
                            printNodeRows(node, depth: 0)
                        }
                    }
                    .background(AppTheme.Colors.surface(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(AppTheme.Colors.fieldBorderVariant(scheme), lineWidth: 1)
                    )
                    .padding(16)
                }

                Divider()

                // MARK: Action Buttons
                HStack(spacing: 12) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.Colors.surfaceContainer(scheme))
                        .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous))

                    Button { presentPrintDialog() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "printer.fill")
                            Text("Print")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.Colors.accent(scheme))
                        .foregroundStyle(AppTheme.Colors.buttonText(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(AppTheme.Colors.background(scheme).ignoresSafeArea())
            .navigationTitle("Print Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Hierarchical Row Renderer

    /// Recursively renders a node and all its descendants with depth-based indentation.
    @ViewBuilder
    private func printNodeRows(_ node: PrintOrderNode, depth: Int) -> some View {
        printNodeRow(node, depth: depth)

        if let children = node.children {
            ForEach(children) { child in
                printNodeRows(child, depth: depth + 1)
            }
        }
    }

    @ViewBuilder
    private func printNodeRow(_ node: PrintOrderNode, depth: Int) -> some View {
        let indent = CGFloat(depth) * 14

        HStack(spacing: 0) {
            // Indentation spacer
            if depth > 0 {
                Spacer().frame(width: indent)

                // Connector line hint
                Rectangle()
                    .fill(AppTheme.Colors.fieldBorderVariant(scheme))
                    .frame(width: 1, height: 14)
                    .padding(.trailing, 6)
            }

            // Label
            Text(node.name)
                .font(labelFont(for: depth))
                .foregroundStyle(labelColor(for: depth))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // QTY — only on leaf items
            if node.isLeaf, let qty = node.quantity {
                Text("×\(qty)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                    .padding(.leading, 8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, rowPadding(for: depth))
        .background(rowBackground(for: depth))

        // Divider after each row — thinner for deeper levels
        Divider()
            .opacity(depth == 0 ? 0.8 : 0.3)
    }

    // MARK: - Styling Helpers

    private func labelFont(for depth: Int) -> Font {
        switch depth {
        case 0:  return .system(size: 12, weight: .bold)
        case 1:  return .system(size: 12, weight: .semibold)
        case 2:  return .system(size: 11, weight: .medium)
        default: return .system(size: 11, weight: .regular)
        }
    }

    private func labelColor(for depth: Int) -> Color {
        switch depth {
        case 0:  return AppTheme.Colors.primaryText(scheme)
        case 1:  return AppTheme.Colors.primaryText(scheme)
        case 2:  return AppTheme.Colors.secondaryText(scheme)
        default: return AppTheme.Colors.secondaryText(scheme).opacity(0.85)
        }
    }

    private func rowPadding(for depth: Int) -> CGFloat {
        depth == 0 ? 10 : 7
    }

    @ViewBuilder
    private func rowBackground(for depth: Int) -> some View {
        switch depth {
        case 0:
            AppTheme.Colors.surfaceContainer(scheme)
        case 1:
            AppTheme.Colors.surfaceContainer(scheme).opacity(0.5)
        default:
            Color.clear
        }
    }

    // MARK: - Native Print Dialog

    private func presentPrintDialog() {
        let info = UIPrintInfo(dictionary: nil)
        info.jobName = "South Lambeth Print Order"
        info.outputType = .general

        let body = buildPrintText(nodes: nodes, depth: 0)
        let header = "SOUTH LAMBETH — Food & Wine Store\nPrint Order — \(Date().formatted())\n\n"

        let controller = UIPrintInteractionController.shared
        controller.printInfo = info
        controller.printFormatter = UISimpleTextPrintFormatter(text: header + body)
        controller.present(animated: true)
    }

    /// Recursively builds indented plain-text for the native print dialog.
    private func buildPrintText(nodes: [PrintOrderNode], depth: Int) -> String {
        let indent = String(repeating: "    ", count: depth)
        return nodes.map { node in
            let qtyStr = node.isLeaf ? (node.quantity.map { "  ×\($0)" } ?? "") : ""
            let line = "\(indent)\(node.name)\(qtyStr)"
            if let children = node.children, !children.isEmpty {
                return line + "\n" + buildPrintText(nodes: children, depth: depth + 1)
            }
            return line
        }.joined(separator: "\n")
    }

    // MARK: - Fallback sample data
    // MARK: Firebase – pending: remove once real inventory quantities are available.

    private var fallbackNodes: [PrintOrderNode] {
        [
            PrintOrderNode(name: "Soft Drinks", level: .mainCategory, children: [
                PrintOrderNode(name: "500ml Bottle", level: .subcategory, children: [
                    PrintOrderNode(name: "Coca Cola", level: .group, children: [
                        PrintOrderNode(name: "Coca Cola Original 500ml", level: .item, quantity: 1),
                        PrintOrderNode(name: "Coca Cola Zero Sugar 500ml", level: .item, quantity: 1)
                    ]),
                    PrintOrderNode(name: "Lucozade", level: .group, children: [
                        PrintOrderNode(name: "Lucozade Orange 500ml", level: .item, quantity: 1)
                    ])
                ]),
                PrintOrderNode(name: "2L Bottle", level: .subcategory, children: [
                    PrintOrderNode(name: "Soft Drinks", level: .group, children: [
                        PrintOrderNode(name: "7up 2L", level: .item, quantity: 1)
                    ])
                ])
            ]),
            PrintOrderNode(name: "Energy Drinks", level: .mainCategory, children: [
                PrintOrderNode(name: "Energy Can", level: .subcategory, children: [
                    PrintOrderNode(name: "Red Bull", level: .group, children: [
                        PrintOrderNode(name: "Red Bull Original 250ml", level: .item, quantity: 2)
                    ]),
                    PrintOrderNode(name: "Monster", level: .group, children: [
                        PrintOrderNode(name: "Monster Energy 500ml", level: .item, quantity: 1)
                    ])
                ])
            ]),
            PrintOrderNode(name: "Still Water", level: .mainCategory, children: [
                PrintOrderNode(name: "Water Still", level: .subcategory, children: [
                    PrintOrderNode(name: "Water", level: .group, children: [
                        PrintOrderNode(name: "Evian 1.5L", level: .item, quantity: 5),
                        PrintOrderNode(name: "Ribena Blackcurrant 500ml", level: .item, quantity: 1)
                    ])
                ])
            ])
        ]
    }
}

// MARK: - Previews

#Preview("Drawer - Light") {
    struct Wrapper: View {
        @State private var open = true
        var body: some View {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                AppDrawer(isOpen: $open, onLogout: {})
            }
        }
    }
    return Wrapper().preferredColorScheme(.light)
}

#Preview("Drawer - Dark") {
    struct Wrapper: View {
        @State private var open = true
        var body: some View {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                AppDrawer(isOpen: $open, onLogout: {})
            }
        }
    }
    return Wrapper().preferredColorScheme(.dark)
}

#Preview("Print Sheet - Light") {
    PrintSheetView(printList: DefaultPrintOrderData.defaultList)
        .preferredColorScheme(.light)
}

#Preview("Print Sheet - Dark") {
    PrintSheetView(printList: DefaultPrintOrderData.defaultList)
        .preferredColorScheme(.dark)
}

#Preview("Print Sheet - No List") {
    PrintSheetView(printList: nil)
        .preferredColorScheme(.light)
}
