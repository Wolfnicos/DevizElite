import SwiftUI
import CoreData

struct ClientsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Client.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)])
    private var clients: FetchedResults<Client>

    @State private var showingEditor: Bool = false
    @State private var selectedClient: Client?

    var body: some View {
        VStack {
            HStack {
                Text(L10n.t("Clients")).font(.title)
                Spacer()
                Button { addClient() } label: { Label(L10n.t("New Client"), systemImage: "plus") }
                    .primaryButton()
            }
            .padding([.horizontal, .top])
            List(selection: $selectedClient) {
                ForEach(clients) { client in
                    Button(action: { selectedClient = client; showingEditor = true }) {
                        VStack(alignment: .leading) {
                            Text(client.name ?? "").font(.headline)
                            if let email = client.contactEmail, !email.isEmpty {
                                Text(email).foregroundColor(.secondary)
                            }
                        }
                    }
                    .contextMenu { Button(role: .destructive) { delete(client) } label: { Label(L10n.t("Delete"), systemImage: "trash") } }
                }
                .onDelete(perform: delete)
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let client = selectedClient {
                ClientEditorView(client: client)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private func addClient() {
        let client = Client(context: viewContext)
        client.id = UUID()
        client.name = "New Client"
        selectedClient = client
        showingEditor = true
        try? viewContext.save()
    }

    private func delete(_ offsets: IndexSet) {
        offsets.map { clients[$0] }.forEach(viewContext.delete)
        try? viewContext.save()
    }

    private func delete(_ client: Client) { viewContext.delete(client); try? viewContext.save() }
}

private struct ClientEditorView: View {
    @ObservedObject var client: Client
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            TextField(L10n.t("Name"), text: Binding(get: { client.name ?? "" }, set: { client.name = $0 }))
            TextField(L10n.t("Email"), text: Binding(get: { client.contactEmail ?? "" }, set: { client.contactEmail = $0 }))
            TextField(L10n.t("Phone"), text: Binding(get: { client.phone ?? "" }, set: { client.phone = $0 }))
            TextField(L10n.t("Address"), text: Binding(get: { client.address ?? "" }, set: { client.address = $0 }))
            TextField(L10n.t("City"), text: Binding(get: { client.city ?? "" }, set: { client.city = $0 }))
            TextField(L10n.t("Country"), text: Binding(get: { client.country ?? "" }, set: { client.country = $0 }))
            TextField(L10n.t("Tax ID"), text: Binding(get: { client.taxId ?? "" }, set: { client.taxId = $0 }))
            TextField(L10n.t("Notes"), text: Binding(get: { client.notes ?? "" }, set: { client.notes = $0 }))
            HStack {
                Spacer()
                Button(L10n.t("Save")) { UIUtilities.endEditing(); viewContext.perform { try? viewContext.save(); DispatchQueue.main.async { dismiss() } } }
                    .primaryButton()
                Button(role: .destructive) {
                    UIUtilities.endEditing()
                    let alert = NSAlert()
                    alert.messageText = L10n.t("Delete this client?")
                    alert.informativeText = L10n.t("This will also remove its association from documents.")
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: L10n.t("Delete"))
                    alert.addButton(withTitle: L10n.t("Cancel"))
                    if alert.runModal() == .alertFirstButtonReturn {
                        viewContext.perform {
                            viewContext.delete(client)
                            try? viewContext.save()
                            DispatchQueue.main.async { dismiss() }
                        }
                    }
                } label: { Text(L10n.t("Delete")) }
            }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 400)
        .themedCard()
    }
}



