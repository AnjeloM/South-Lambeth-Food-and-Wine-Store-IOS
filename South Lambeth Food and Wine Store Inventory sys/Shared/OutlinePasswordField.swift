import SwiftUI

public struct OutlinedPasswordField: View {
    public let title: String
    public let placeholder: String
    @Binding public var text: String

    public let isVisible: Bool
    public let isDisabled: Bool
    public let accessibilityLabel: String?
    public let onToggleVisibility: () -> Void

    @Environment(\.colorScheme) private var scheme

    public init(
        title: String,
        placeholder: String = "",
        text: Binding<String>,
        isVisible: Bool,
        isDisabled: Bool = false,
        accessibilityLabel: String? = nil,
        onToggleVisibility: @escaping () -> Void
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.isVisible = isVisible
        self.isDisabled = isDisabled
        self.accessibilityLabel = accessibilityLabel
        self.onToggleVisibility = onToggleVisibility
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))

            HStack(spacing: 10) {
                Group {
                    if isVisible {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .textContentType(.password)
                .font(AppTheme.Typography.fieldValue)

                Button(action: onToggleVisibility) {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Toggle password visibility")
            }
            .padding(.leading, 14)
            .padding(.vertical, 6)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.Colors.fieldBorder(scheme), lineWidth: AppTheme.Layout.fieldBorderWidth)
                    .allowsHitTesting(false) // <- ensure taps go to the field and button
            )
            .disabled(isDisabled)
            .accessibilityLabel(accessibilityLabel ?? title)
        }
    }
}