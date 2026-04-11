import SwiftUI

// MARK: - InventoryScreen
//
// Pure view — renders InventoryUiState, emits InventoryUiEvent.
// Zero business logic, zero ViewModel reference.

public struct InventoryScreen: View {

    public let state: InventoryUiState
    public let onEvent: (InventoryUiEvent) -> Void
    public let onDrawerTapped: () -> Void

    public init(
        state: InventoryUiState,
        onEvent: @escaping (InventoryUiEvent) -> Void,
        onDrawerTapped: @escaping () -> Void = {}
    ) {
        self.state          = state
        self.onEvent        = onEvent
        self.onDrawerTapped = onDrawerTapped
    }

    @Environment(\.colorScheme) private var scheme

    // Pure UI state — sheet open/close is not a business concern (same as isDrawerOpen).
    @State private var isPickerPresented = false

    // Binding bridge — AppSearchFilterBar needs a Binding<String>
    private var searchBinding: Binding<String> {
        Binding(
            get: { state.searchText },
            set: { onEvent(.searchChanged($0)) }
        )
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {

            // MARK: Header
            AppScreenHeader(title: "Inventory", onDrawerTapped: onDrawerTapped)

            // MARK: Search & Filter
            AppSearchFilterBar(text: searchBinding)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // MARK: Week Header Bar
            weekHeaderBar

            // MARK: Scrollable content
            ScrollView {
                VStack(spacing: 12) {

                    // MARK: Primary action — Create / Edit Inventory
                    createOrEditButton
                        .padding(.horizontal, AppTheme.Layout.screenHPadding)
                        .padding(.top, 16)

                    // MARK: Compact filter card group
                    filterCardGroup
                        .padding(.horizontal, AppTheme.Layout.screenHPadding)

                    // MARK: Item list
                    inventoryList
                        .padding(.top, 4)
                }
                .padding(.bottom, 24)
            }
        }
        .background(AppTheme.Colors.background(scheme).ignoresSafeArea())
        .sheet(isPresented: $isPickerPresented) {
            InventoryWeekPickerSheet(
                selectedWeek:    state.selectedWeek,
                selectedMonth:   state.selectedMonth,
                selectedYear:    state.selectedYear,
                onWeekSelected:  { onEvent(.onSelectWeek($0)) },
                onMonthSelected: { onEvent(.onSelectMonth($0)) },
                onYearSelected:  { onEvent(.onSelectYear($0)) },
                onDismiss:       { isPickerPresented = false }
            )
        }
    }

    // MARK: - Week Header Bar

    private var weekHeaderBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accent(scheme))

            Text(state.weekHeaderLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                .lineLimit(1)

            Spacer()

            Button { isPickerPresented = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Change")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(AppTheme.Colors.accent(scheme))
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(Capsule(style: .continuous).fill(AppTheme.Colors.surfaceContainer(scheme)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.Layout.screenHPadding)
        .padding(.vertical, 10)
        .background(AppTheme.Colors.background(scheme))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.Colors.fieldBorderVariant(scheme))
                .frame(height: 0.5)
        }
    }

    // MARK: - Create / Edit Inventory — Primary Action Button

    private var createOrEditButton: some View {
        let exists = state.inventoryExistsForSelectedWeek
        let icon   = exists ? "square.and.pencil"   : "plus.square.fill"
        let title  = exists ? "Edit Inventory"       : "Create New Inventory"

        return Button { onEvent(.onTapCreateOrEditInventory) } label: {
            HStack(spacing: 14) {

                // Leading: icon in a circle
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.buttonText(scheme).opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.buttonText(scheme))
                }

                // Center: title + week context
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.buttonText(scheme))
                    Text(state.weekHeaderLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.buttonText(scheme).opacity(0.75))
                }

                Spacer()

                // Trailing chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.buttonText(scheme).opacity(0.75))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                    .fill(AppTheme.Colors.accent(scheme))
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: exists)
    }

    // MARK: - Compact Filter Card Group

    private var filterCardGroup: some View {
        HStack(spacing: 8) {
            filterCard(
                value:  "\(state.totalItemCount)",
                label:  "Total Items",
                icon:   "shippingbox.fill",
                filter: .totalItems
            )
            filterCard(
                value:  "\(state.lowStockCount)",
                label:  "Low Stock",
                icon:   "exclamationmark.triangle.fill",
                filter: .lowStock
            )
            filterCard(
                value:  "\(state.outOfStockCount)",
                label:  "Out of Stock",
                icon:   "xmark.circle.fill",
                filter: .outOfStock
            )
        }
    }

    // MARK: - Filter Card (compact, equal-width)

    @ViewBuilder
    private func filterCard(
        value: String,
        label: String,
        icon: String,
        filter: InventoryFilter
    ) -> some View {
        let isActive = state.activeFilter == filter

        Button { onEvent(.onTapFilter(filter)) } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(
                        isActive
                            ? AppTheme.Colors.buttonText(scheme)
                            : AppTheme.Colors.accent(scheme)
                    )

                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(
                        isActive
                            ? AppTheme.Colors.buttonText(scheme)
                            : AppTheme.Colors.primaryText(scheme)
                    )

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(
                        isActive
                            ? AppTheme.Colors.buttonText(scheme)
                            : AppTheme.Colors.secondaryText(scheme)
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                    .fill(
                        isActive
                            ? AppTheme.Colors.accent(scheme)
                            : AppTheme.Colors.surfaceContainer(scheme)
                    )
            )
            // Active: accent 2pt stroke to reinforce selection beyond fill change
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                    .strokeBorder(
                        isActive ? AppTheme.Colors.accent(scheme) : Color.clear,
                        lineWidth: 2
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isActive)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Inventory List

    private var inventoryList: some View {
        Group {
            if state.filteredItems.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(state.filteredItems) { item in
                        inventoryRow(item)
                        if item.id != state.filteredItems.last?.id {
                            Divider()
                                .padding(.leading, AppTheme.Layout.screenHPadding)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                        .fill(AppTheme.Colors.surfaceContainer(scheme))
                )
                .padding(.horizontal, AppTheme.Layout.screenHPadding)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 34))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            Text("No items match the current filter")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Inventory Row

    @ViewBuilder
    private func inventoryRow(_ item: InventoryItem) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.Colors.primaryContainer(scheme))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: item.icon)
                        .foregroundStyle(AppTheme.Colors.onPrimaryContainer(scheme))
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                Text(item.category)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 4) {
                    if item.isOutOfStock {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.Colors.error(scheme))
                    } else if item.isLowStock {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.Colors.error(scheme))
                    }
                    Text(item.isOutOfStock ? "Out of stock" : "\(item.stock) units")
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            item.isOutOfStock || item.isLowStock
                                ? AppTheme.Colors.error(scheme)
                                : AppTheme.Colors.primaryText(scheme)
                        )
                }
                Text(item.sku)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            }
        }
        .padding(.horizontal, AppTheme.Layout.screenHPadding)
        .padding(.vertical, 12)
    }
}

// MARK: - Calendar grid helpers

private struct CalendarDayCell {
    let day: Int?
    let weekOfYear: Int
    let isCurrentMonth: Bool
}

private struct CalendarWeekRow: Identifiable {
    let id: Int
    let weekOfYear: Int
    let cells: [CalendarDayCell]
}

/// Produces the week-row grid for a given month/year — UI layout helper, not business logic.
private func buildCalendarWeeks(month: Int, year: Int) -> [CalendarWeekRow] {
    var cal = Calendar(identifier: .gregorian)
    cal.firstWeekday = 2  // Monday-first

    var comps = DateComponents()
    comps.year  = year
    comps.month = month
    comps.day   = 1

    guard let firstDate   = cal.date(from: comps),
          let daysInMonth = cal.range(of: .day, in: .month, for: firstDate)?.count
    else { return [] }

    let firstWeekday = cal.component(.weekday, from: firstDate)
    let leadingPad   = (firstWeekday - 2 + 7) % 7

    var flat: [(day: Int?, woy: Int, isCurrent: Bool)] =
        Array(repeating: (day: Optional<Int>.none, woy: 0, isCurrent: false), count: leadingPad)

    for day in 1...daysInMonth {
        comps.day = day
        let woy = cal.date(from: comps)
            .flatMap { cal.dateComponents([.weekOfYear], from: $0).weekOfYear } ?? 0
        flat.append((day, woy, true))
    }

    let remainder = flat.count % 7
    if remainder != 0 {
        flat.append(contentsOf: Array(
            repeating: (day: Optional<Int>.none, woy: 0, isCurrent: false),
            count: 7 - remainder
        ))
    }

    var rows: [CalendarWeekRow] = []
    var idx = 0
    while idx < flat.count {
        let slice = Array(flat[idx..<idx + 7])
        let woy   = slice.first(where: { $0.isCurrent })?.woy ?? (rows.last?.weekOfYear ?? 0) + 1
        let cells = slice.map { CalendarDayCell(day: $0.day, weekOfYear: $0.woy, isCurrentMonth: $0.isCurrent) }
        rows.append(CalendarWeekRow(id: idx, weekOfYear: woy, cells: cells))
        idx += 7
    }
    return rows
}

// MARK: - InventoryWeekPickerSheet
//
// Calendar-style week picker. Each row = one week; tap a row to select it.
// No single-day selection. Month/year navigation via chevron arrows + year wheel.

private struct InventoryWeekPickerSheet: View {

    @State private var pickerMonth: Int
    @State private var pickerYear:  Int
    @State private var pickerWeek:  Int

    let onWeekSelected:  (Int) -> Void
    let onMonthSelected: (Int) -> Void
    let onYearSelected:  (Int) -> Void
    let onDismiss:       () -> Void

    @Environment(\.colorScheme) private var scheme

    private static let years:      [Int]    = Array(2020...2035)
    private static let monthNames: [String] = Calendar.current.monthSymbols
    private static let dayHeaders: [String] = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    init(
        selectedWeek:    Int,
        selectedMonth:   Int,
        selectedYear:    Int,
        onWeekSelected:  @escaping (Int) -> Void,
        onMonthSelected: @escaping (Int) -> Void,
        onYearSelected:  @escaping (Int) -> Void,
        onDismiss:       @escaping () -> Void
    ) {
        _pickerWeek  = State(initialValue: selectedWeek)
        _pickerMonth = State(initialValue: selectedMonth)
        _pickerYear  = State(initialValue: selectedYear)
        self.onWeekSelected  = onWeekSelected
        self.onMonthSelected = onMonthSelected
        self.onYearSelected  = onYearSelected
        self.onDismiss       = onDismiss
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Drag handle
            Capsule()
                .fill(AppTheme.Colors.fieldBorderVariant(scheme))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 14)

            // MARK: Title
            Text("Select Inventory Week")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                .padding(.bottom, 2)

            Text("Tap a week row to select it")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                .padding(.bottom, 14)

            Divider()

            // MARK: Month / Year navigation  ← Month Year →
            monthYearNav
                .padding(.vertical, 14)

            // MARK: Year picker wheel (compact)
            yearPickerRow
                .padding(.bottom, 8)

            Divider()

            // MARK: Day-of-week header
            dayOfWeekHeader
                .padding(.vertical, 8)
                .background(AppTheme.Colors.surfaceContainer(scheme))

            // MARK: Calendar week rows
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(buildCalendarWeeks(month: pickerMonth, year: pickerYear)) { week in
                        calendarWeekRow(week)
                    }
                }
                .padding(.horizontal, AppTheme.Layout.screenHPadding)
                .padding(.vertical, 8)
            }

            Divider()

            // MARK: Done button
            Button(action: onDismiss) {
                Text("Done")
                    .font(AppTheme.Typography.button)
                    .foregroundStyle(AppTheme.Colors.buttonText(scheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Layout.pillCornerRadious, style: .continuous)
                            .fill(AppTheme.Colors.accent(scheme))
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppTheme.Layout.screenHPadding)
            .padding(.top, 14)
            .padding(.bottom, 32)
        }
        .background(AppTheme.Colors.background(scheme))
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Month / Year navigation  ← April 2026 →

    private var monthYearNav: some View {
        HStack(spacing: 0) {
            Button { stepMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent(scheme))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(AppTheme.Colors.surfaceContainer(scheme)))
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(Self.monthNames[pickerMonth - 1])
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                Text(String(pickerYear))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            }

            Spacer()

            Button { stepMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent(scheme))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(AppTheme.Colors.surfaceContainer(scheme)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.Layout.screenHPadding)
    }

    // MARK: - Year picker row (compact wheel)

    private var yearPickerRow: some View {
        HStack(spacing: 8) {
            Text("Year")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))

            Picker("Year", selection: $pickerYear) {
                ForEach(Self.years, id: \.self) { y in
                    Text(String(y)).tag(y)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 80)
            .onChange(of: pickerYear) { y in onYearSelected(y) }
        }
        .padding(.horizontal, AppTheme.Layout.screenHPadding)
    }

    // MARK: - Day-of-week header

    private var dayOfWeekHeader: some View {
        HStack(spacing: 0) {
            Text("Wk")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                .frame(width: 34)

            ForEach(Self.dayHeaders, id: \.self) { header in
                Text(header)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, AppTheme.Layout.screenHPadding)
    }

    // MARK: - Calendar week row

    @ViewBuilder
    private func calendarWeekRow(_ week: CalendarWeekRow) -> some View {
        let isSelected = pickerWeek == week.weekOfYear

        Button {
            pickerWeek = week.weekOfYear
            onWeekSelected(week.weekOfYear)
        } label: {
            HStack(spacing: 0) {
                // Week number badge
                Text("\(week.weekOfYear)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(
                        isSelected
                            ? AppTheme.Colors.buttonText(scheme)
                            : AppTheme.Colors.accent(scheme)
                    )
                    .frame(width: 34)

                // Day cells
                ForEach(0..<7, id: \.self) { i in
                    let cell = week.cells[i]
                    ZStack {
                        if let day = cell.day {
                            Text("\(day)")
                                .font(.system(size: 14, weight: cell.isCurrentMonth ? .medium : .regular))
                                .foregroundStyle(
                                    isSelected
                                        ? AppTheme.Colors.buttonText(scheme)
                                        : (cell.isCurrentMonth
                                            ? AppTheme.Colors.primaryText(scheme)
                                            : AppTheme.Colors.secondaryText(scheme).opacity(0.35))
                                )
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 38)
                }
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? AppTheme.Colors.accent(scheme) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    // MARK: - Month step helper

    private func stepMonth(by delta: Int) {
        var m = pickerMonth + delta
        var y = pickerYear
        if m < 1  { m = 12; y -= 1 }
        if m > 12 { m = 1;  y += 1 }
        pickerMonth = m
        pickerYear  = y
        onMonthSelected(m)
        onYearSelected(y)
    }
}

// MARK: - Previews

#Preview("All Items — Light") {
    InventoryScreen(
        state:   InventoryUiState(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("All Items — Dark") {
    InventoryScreen(
        state:   InventoryUiState(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("Low Stock Filter") {
    InventoryScreen(
        state:   InventoryUiState(activeFilter: .lowStock),
        onEvent: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("Out of Stock Filter") {
    InventoryScreen(
        state:   InventoryUiState(activeFilter: .outOfStock),
        onEvent: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("No Existing Inventory — Week 16") {
    InventoryScreen(
        state:   InventoryUiState(selectedWeek: 16, inventoryExistsForSelectedWeek: false),
        onEvent: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("No Existing Inventory — Dark") {
    InventoryScreen(
        state:   InventoryUiState(selectedWeek: 16, inventoryExistsForSelectedWeek: false),
        onEvent: { _ in }
    )
    .preferredColorScheme(.dark)
}
