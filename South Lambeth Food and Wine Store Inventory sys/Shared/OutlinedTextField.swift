import SwiftUI

public struct OutlinedTextField: View {
    public let title: String
    public let placeholder: String
    public let value: String
    public let keyboard: UIKeyboardType
    public let textContentType: UITextContentType?
    public let autocapitalization: TextInputAutocapitalization
    public let isDisabled: Bool
    public let accessibilityLabel: String?
    public let onChanged: (String) -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var internalValue: String = ""

    public init(
        title: String,
        placeholder: String = "",
        value: String,
        keyboard: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        autocapitalization: TextInputAutocapitalization = .sentences,
        isDisabled: Bool = false,
        accessibilityLabel: String? = nil,
        onChanged: @escaping (String) -> Void
    ) {
        self.title = title
        self.placeholder = placeholder
        self.value = value
        self.keyboard = keyboard
        self.textContentType = textContentType
        self.autocapitalization = autocapitalization
        self.isDisabled = isDisabled
        self.accessibilityLabel = accessibilityLabel
        self.onChanged = onChanged
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))

            TextField(
                placeholder,
                text: Binding(
                    get: { internalValue },
                    set: { newValue in
                        internalValue = newValue
                        onChanged(newValue)
                    }
                )
            )
            .onAppear { internalValue = value }
            .keyboardType(keyboard)
            .textContentType(textContentType)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled(true)
            .font(AppTheme.Typography.fieldValue)
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.Colors.fieldBorder(scheme), lineWidth: AppTheme.Layout.fieldBorderWidth)
            )
            .disabled(isDisabled)
            .accessibilityLabel(accessibilityLabel ?? title)
        }
    }
}
