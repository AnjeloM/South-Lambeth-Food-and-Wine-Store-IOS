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

    public init(isOpen: Binding<Bool>, onLogout: @escaping () -> Void) {
        self._isOpen = isOpen
        self.onLogout = onLogout
    }

    @Environment(\.colorScheme) private var scheme

    @State private var showPrintSheet       = false
    @State private var showSetPrintOrder    = false

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
            PrintSheetView()
        }
        .sheet(isPresented: $showSetPrintOrder) {
            SetPrintOrderSheetView()
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

                    // Set Print Order — opens order sheet
                    drawerRow(item: DrawerItem(
                        icon: "arrow.up.arrow.down.circle.fill",
                        label: "Set Print Order",
                        action: { showSetPrintOrder = true }
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

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: Print Preview
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SOUTH LAMBETH")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                            Text("Food & Wine Store — Inventory Report")
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

                        // Column headers
                        printRowHeader

                        Divider()

                        // Sample rows
                        ForEach(Array(samplePrintItems.enumerated()), id: \.offset) { index, item in
                            printRow(item: item, shaded: index.isMultiple(of: 2))
                            Divider().opacity(0.4)
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
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.Colors.surfaceContainer(scheme))
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous))

                    Button {
                        presentPrintDialog()
                    } label: {
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

    // MARK: - Print Row Header

    private var printRowHeader: some View {
        HStack {
            Text("Item")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("SKU")
                .frame(width: 72, alignment: .leading)
            Text("Stock")
                .frame(width: 48, alignment: .trailing)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Print Row

    @ViewBuilder
    private func printRow(item: (name: String, sku: String, stock: Int), shaded: Bool) -> some View {
        HStack {
            Text(item.name)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            Text(item.sku)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                .frame(width: 72, alignment: .leading)
            Text("\(item.stock)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(item.stock < 10
                    ? AppTheme.Colors.error(scheme)
                    : AppTheme.Colors.primaryText(scheme))
                .frame(width: 48, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(shaded ? AppTheme.Colors.surfaceContainer(scheme).opacity(0.5) : Color.clear)
    }

    // MARK: - Native Print Dialog

    private func presentPrintDialog() {
        let info = UIPrintInfo(dictionary: nil)
        info.jobName = "South Lambeth Inventory Report"
        info.outputType = .general

        let text = samplePrintItems
            .map { "\($0.name)\t\($0.sku)\t\($0.stock) units" }
            .joined(separator: "\n")
        let header = "SOUTH LAMBETH — Food & Wine Store\nInventory Report — \(Date().formatted())\n\n"

        let controller = UIPrintInteractionController.shared
        controller.printInfo = info
        controller.printFormatter = UISimpleTextPrintFormatter(text: header + text)
        controller.present(animated: true)
    }

    // MARK: - Sample Data (replace with real inventory when data layer is wired)

    private let samplePrintItems: [(name: String, sku: String, stock: Int)] = [
        ("Merlot Red Wine 75cl",      "WN-001", 48),
        ("Heineken 330ml",            "BR-012", 120),
        ("Grey Goose Vodka 70cl",     "SP-034", 7),
        ("Coca-Cola 2L",              "SD-007", 60),
        ("Prosecco Brut 75cl",        "WN-022", 3),
        ("Walkers Crisps (Box)",      "SN-005", 24),
        ("Jack Daniel's 70cl",        "SP-011", 15),
        ("San Pellegrino 500ml",      "SD-019", 42),
    ]
}

// MARK: - Set Print Order Sheet

// MARK: Firebase – pending
// This screen will let users reorder items to control how they appear in the printed report.
// Implement with SwiftUI List drag-to-reorder once inventory data layer is wired.
private struct SetPrintOrderSheetView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "arrow.up.arrow.down.circle")
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.Colors.accent(scheme))

                VStack(spacing: 8) {
                    Text("Set Print Order")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                    Text("Drag items to set the order in which\nthey appear on printed reports.")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                        .multilineTextAlignment(.center)
                }

                Text("Coming soon")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.buttonText(scheme))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(AppTheme.Colors.accent(scheme))
                    .clipShape(Capsule())

                Spacer()
            }
            .padding(AppTheme.Layout.screenHPadding)
            .background(AppTheme.Colors.background(scheme).ignoresSafeArea())
            .navigationTitle("Set Print Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
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
    PrintSheetView()
        .preferredColorScheme(.light)
}

#Preview("Print Sheet - Dark") {
    PrintSheetView()
        .preferredColorScheme(.dark)
}
