import AppKit

enum UIUtilities {
    static func endEditing() {
        NSApp.keyWindow?.makeFirstResponder(nil)
    }
}


