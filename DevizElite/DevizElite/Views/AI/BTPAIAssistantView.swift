import SwiftUI

struct BTPAIAssistantView: View {
    @ObservedObject var document: Document
    @State private var isPresented = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            IntelligentChatView(document: document)
                .navigationTitle("🤖 Assistant BTP Intelligent")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") {
                            dismiss()
                        }
                    }
                }
        }
        .frame(minWidth: 1200, minHeight: 900)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - Preview
struct BTPAIAssistantView_Previews: PreviewProvider {
    static var previews: some View {
        BTPAIAssistantView(document: Document())
    }
}