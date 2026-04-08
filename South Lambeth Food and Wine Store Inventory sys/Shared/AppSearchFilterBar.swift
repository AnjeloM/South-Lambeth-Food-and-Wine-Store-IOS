import SwiftUI

// MARK: - AppSearchFilterBar
//
// Design reference: Components/Search_and_filter.png
// Layout: [🔍  Search Item... ──────────────] [⊟]
//
// Usage (stateless — caller owns the binding):
//   AppSearchFilterBar(text: $searchText, onFilterTapped: { })

public struct AppSearchFilterBar: View {

    @Binding public var text: String
    public var placeholder: String
    public let onFilterTapped: () -> Void

    public init(
        text: Binding<String>,
        placeholder: String = "Search Item...",
        onFilterTapped: @escaping () -> Void = {}
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onFilterTapped = onFilterTapped
    }

    @Environment(\.colorScheme) private var scheme

    // Surface container sits one level above the page background in both themes —
    // light: soft grey pill on white  |  dark: elevated dark pill on dark background
    private var fieldFill: Color { AppTheme.Colors.surfaceContainer(scheme) }

    private var fieldText: Color { AppTheme.Colors.primaryText(scheme) }

    private var placeholderText: Color { AppTheme.Colors.secondaryText(scheme) }

    public var body: some View {
        HStack(spacing: 10) {

            // MARK: Search Field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(placeholderText)

                TextField("", text: $text, prompt:
                    Text(placeholder).foregroundColor(placeholderText)
                )
                .font(.system(size: 15))
                .foregroundStyle(fieldText)
                .tint(AppTheme.Colors.accent(scheme))
                .autocorrectionDisabled()

                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(placeholderText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                Capsule(style: .continuous)
                    .fill(fieldFill)
            )

            // MARK: Filter Button
            Button(action: onFilterTapped) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(fieldText)
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(fieldFill)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.Layout.screenHPadding)
    }
}

// MARK: - Previews

#Preview("AppSearchFilterBar - Light") {
    struct Wrapper: View {
        @State private var q = ""
        var body: some View {
            VStack {
                AppSearchFilterBar(text: $q)
                Spacer()
            }
            .padding(.top, 16)
        }
    }
    return Wrapper().preferredColorScheme(.light)
}

#Preview("AppSearchFilterBar - Dark") {
    struct Wrapper: View {
        @State private var q = ""
        var body: some View {
            VStack {
                AppSearchFilterBar(text: $q)
                Spacer()
            }
            .padding(.top, 16)
        }
    }
    return Wrapper().preferredColorScheme(.dark)
}
