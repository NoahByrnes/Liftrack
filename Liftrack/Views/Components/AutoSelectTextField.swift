import SwiftUI
#if canImport(UIKit)
import UIKit

// Custom UITextField that auto-selects all text when focused
class AutoSelectUITextField: UITextField {
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            // Delay selection to ensure text is loaded
            DispatchQueue.main.async {
                self.selectAll(nil)
            }
        }
        return result
    }
}

// SwiftUI wrapper for the auto-select text field
struct AutoSelectTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textAlignment: NSTextAlignment = .center
    var font: UIFont = .systemFont(ofSize: 16, weight: .medium)
    var onCommit: (() -> Void)?
    
    func makeUIView(context: Context) -> AutoSelectUITextField {
        let textField = AutoSelectUITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = keyboardType
        textField.textAlignment = textAlignment
        textField.font = font
        textField.placeholder = placeholder
        textField.text = text
        
        // Add toolbar with Done button for number pads
        if keyboardType == .numberPad || keyboardType == .decimalPad {
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let doneButton = UIBarButtonItem(title: "Done", style: .done, target: textField, action: #selector(UITextField.resignFirstResponder))
            toolbar.items = [flexSpace, doneButton]
            textField.inputAccessoryView = toolbar
        }
        
        return textField
    }
    
    func updateUIView(_ uiView: AutoSelectUITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: AutoSelectTextField
        
        init(_ parent: AutoSelectTextField) {
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            parent.onCommit?()
            return true
        }
    }
}
#else
// Fallback for macOS
struct AutoSelectTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        TextField(placeholder, text: $text)
    }
}

enum UIKeyboardType {
    case `default`
    case numberPad
    case decimalPad
}
#endif