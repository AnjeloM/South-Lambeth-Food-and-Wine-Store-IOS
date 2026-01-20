import SwiftUI

public struct OutlinedPasswordField: View {
    public let title: String
    public let placeholder: String
    public let value: String
    public let isVisible: Bool
    public let isDisabled: Bool
    public let accessibilityLabel: String?

    public let onChanged: (String) -> Void
    public let onToggleVisibility: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var internalValue: String = ""

    public init(
        title: String,
        placeholder: String = "",
        value: String,
        isVisible: Bool,
        isDisabled: Bool = false,
        accessibilityLabel: String? = nil,
        onChanged: @escaping (String) -> Void,
        onToggleVisibility: @escaping () -> Void
    ) {
        self.title = title
        self.placeholder = placeholder
        self.value = value
        self.isVisible = isVisible
        self.isDisabled = isDisabled
        self.accessibilityLabel = accessibilityLabel
        self.onChanged = onChanged
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
                        TextField(placeholder, text: binding)
                    } else {
                        SecureField(placeholder, text: binding)
                    }
                }
                .onAppear { internalValue = value }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .textContentType(.password)
                .font(AppTheme.Typography.fieldValue)

                Button(action: onToggleVisibility) {
                    Image(systemName: isVisible ? "eye" : "eye.slash")
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
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.Colors.fieldBorder(scheme), lineWidth: AppTheme.Layout.fieldBorderWidth)
            )
            .disabled(isDisabled)
            .accessibilityLabel(accessibilityLabel ?? title)
        }
    }

    private var binding: Binding<String> {
        Binding(
            get: { internalValue },
            set: { newValue in
                internalValue = newValue
                onChanged(newValue)
            }
        )
    }
}
