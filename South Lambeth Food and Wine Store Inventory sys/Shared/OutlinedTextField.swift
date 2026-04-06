import SwiftUI

public struct OutlinedTextField: View {
    public let title: String
    public let placeholder: String
    @Binding public var text: String
    
    public let keyboard: UIKeyboardType
    public let textContentType: UITextContentType?
    public let autocapitalization: TextInputAutocapitalization
    public let isDisabled: Bool
    public let accessibilityLabel: String?
    
    @Environment(\.colorScheme) private var scheme

    public init(
        title: String,
        placeholder: String = "",
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        autocapitalization: TextInputAutocapitalization = .sentences,
        isDisabled: Bool = false,
        accessibilityLabel: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.keyboard = keyboard
        self.textContentType = textContentType
        self.autocapitalization = autocapitalization
        self.isDisabled = isDisabled
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))

            TextField(placeholder, text: $text)
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
