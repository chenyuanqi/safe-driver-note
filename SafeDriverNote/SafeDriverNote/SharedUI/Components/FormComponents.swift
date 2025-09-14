import SwiftUI

// MARK: - Text Field Style
struct BrandTextFieldStyle: TextFieldStyle {
    let isError: Bool
    let leadingIcon: String?
    
    init(isError: Bool = false, leadingIcon: String? = nil) {
        self.isError = isError
        self.leadingIcon = leadingIcon
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        HStack(spacing: Spacing.lg) {
            if let leadingIcon = leadingIcon {
                Image(systemName: leadingIcon)
                    .font(.body)
                    .foregroundColor(.brandSecondary500)
                    .frame(width: 20, height: 20)
            }
            
            configuration
                .font(.body)
                .foregroundColor(.brandSecondary900)
        }
        .padding(.horizontal, Spacing.cardPadding)
        .padding(.vertical, Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(Color.inputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                        .stroke(isError ? Color.brandDanger500 : Color.brandSecondary300, lineWidth: 1)
                )
        )
    }
}

// MARK: - Search Field Component
struct SearchField: View {
    @Binding var text: String
    let placeholder: String
    let onEditingChanged: ((Bool) -> Void)?
    let onCommit: (() -> Void)?
    
    init(
        text: Binding<String>,
        placeholder: String = "搜索...",
        onEditingChanged: ((Bool) -> Void)? = nil,
        onCommit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onEditingChanged = onEditingChanged
        self.onCommit = onCommit
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundColor(.brandSecondary500)
            
            TextField(placeholder, text: $text, onEditingChanged: onEditingChanged ?? { _ in }, onCommit: onCommit ?? {})
                .font(.body)
                .foregroundColor(.brandSecondary900)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundColor(.brandSecondary300)
                }
                .iconStyle(size: 20)
            }
        }
        .padding(.horizontal, Spacing.cardPadding)
        .padding(.vertical, Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .fill(Color.brandSecondary100)
        )
    }
}

// MARK: - Text Editor Component
struct BrandTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat
    let isError: Bool
    
    init(
        text: Binding<String>,
        placeholder: String = "",
        minHeight: CGFloat = 120,
        isError: Bool = false
    ) {
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.isError = isError
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.body)
                    .foregroundColor(.brandSecondary500)
                    .padding(.horizontal, Spacing.cardPadding)
                    .padding(.vertical, Spacing.lg)
            }
            
            TextEditor(text: $text)
                .font(.body)
                .foregroundColor(.brandSecondary900)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .scrollContentBackground(.hidden)
        }
        .frame(minHeight: minHeight)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(Color.inputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                        .stroke(isError ? Color.brandDanger500 : Color.brandSecondary300, lineWidth: 1)
                )
        )
    }
}

// MARK: - Form Field Component
struct FormField<Content: View>: View {
    let label: String?
    let isRequired: Bool
    let errorMessage: String?
    let helpText: String?
    let content: Content
    
    init(
        label: String? = nil,
        isRequired: Bool = false,
        errorMessage: String? = nil,
        helpText: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.isRequired = isRequired
        self.errorMessage = errorMessage
        self.helpText = helpText
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let label = label {
                HStack(spacing: Spacing.xs) {
                    Text(label)
                        .font(.bodyLarge)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)
                    
                    if isRequired {
                        Text("*")
                            .font(.bodyLarge)
                            .foregroundColor(.brandDanger500)
                    }
                }
            }
            
            content
            
            if let errorMessage = errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.bodySmall)
                    .foregroundColor(.brandDanger500)
            } else if let helpText = helpText {
                Text(helpText)
                    .font(.bodySmall)
                    .foregroundColor(.brandSecondary500)
            }
        }
    }
}

// MARK: - Picker Field Component
struct PickerField<SelectionValue, Content>: View where SelectionValue: Hashable, Content: View {
    let label: String
    @Binding var selection: SelectionValue
    let content: Content
    
    init(
        _ label: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self._selection = selection
        self.content = content()
    }
    
    var body: some View {
        Picker(label, selection: $selection) {
            content
        }
        .pickerStyle(.segmented)
        .background(Color.clear)
    }
}

// MARK: - Toggle Field Component
struct ToggleField: View {
    let label: String
    let subtitle: String?
    @Binding var isOn: Bool
    
    init(_ label: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.label = label
        self.subtitle = subtitle
        self._isOn = isOn
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(label)
                    .font(.body)
                    .foregroundColor(.brandSecondary900)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary500)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .brandPrimary500))
        }
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Stepper Field Component
struct StepperField: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    
    init(_ label: String, value: Binding<Int>, in range: ClosedRange<Int>, step: Int = 1) {
        self.label = label
        self._value = value
        self.range = range
        self.step = step
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.brandSecondary900)
            
            Spacer()
            
            Stepper(
                value: $value,
                in: range,
                step: step
            ) {
                Text("\(value)")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)
                    .frame(minWidth: 40)
            }
            .labelsHidden()
        }
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Multi-Select Field Component
struct MultiSelectField<T: Hashable & Identifiable>: View {
    let title: String
    let items: [T]
    @Binding var selectedItems: Set<T.ID>
    let displayText: (T) -> String
    
    init(
        title: String,
        items: [T],
        selectedItems: Binding<Set<T.ID>>,
        displayText: @escaping (T) -> String
    ) {
        self.title = title
        self.items = items
        self._selectedItems = selectedItems
        self.displayText = displayText
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text(title)
                .font(.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(.brandSecondary900)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80), spacing: Spacing.md)
            ], spacing: Spacing.md) {
                ForEach(items) { item in
                    Button(action: {
                        if selectedItems.contains(item.id) {
                            selectedItems.remove(item.id)
                        } else {
                            selectedItems.insert(item.id)
                        }
                    }) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: selectedItems.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                .font(.bodySmall)
                            
                            Text(displayText(item))
                                .font(.bodySmall)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                                .fill(selectedItems.contains(item.id) ? Color.brandPrimary100 : Color.brandSecondary100)
                        )
                        .foregroundColor(selectedItems.contains(item.id) ? .brandPrimary700 : .brandSecondary700)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Extensions
extension TextField {
    func brandStyle(isError: Bool = false, leadingIcon: String? = nil) -> some View {
        self.textFieldStyle(BrandTextFieldStyle(isError: isError, leadingIcon: leadingIcon))
    }
}