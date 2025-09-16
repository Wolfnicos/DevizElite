import SwiftUI
import CoreData

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModelHolder = Holder()

    private final class Holder: ObservableObject {
        var vm: AuthViewModel?
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("InvoiceMaster Pro").font(.largeTitle).bold()
            TextField("Email", text: Binding(
                get: { viewModelHolder.vm?.email ?? "" },
                set: { viewModelHolder.vm?.email = $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: 360)
            SecureField("Password", text: Binding(
                get: { viewModelHolder.vm?.password ?? "" },
                set: { viewModelHolder.vm?.password = $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: 360)
            HStack(spacing: 12) {
                Button("Sign In") { viewModelHolder.vm?.signIn() }
                    .keyboardShortcut(.defaultAction)
                Button("Register") { viewModelHolder.vm?.register() }
            }
            if let error = viewModelHolder.vm?.errorMessage {
                Text(error).foregroundColor(.red)
            }
        }
        .padding(32)
        .onAppear {
            if viewModelHolder.vm == nil {
                viewModelHolder.vm = AuthViewModel(appState: appState, context: viewContext)
            }
        }
    }
}

#Preview {
    LoginView().environmentObject(AppState()).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


