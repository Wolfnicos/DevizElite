import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct PhotosTab: View {
    @ObservedObject var document: Document
    @Binding var showingGallery: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedPhotos: Set<SitePhoto> = []
    @State private var showingImagePicker = false
    @State private var showingPhotoDetail = false
    @State private var selectedPhoto: SitePhoto?
    @State private var viewMode = 0 // 0: Grid, 1: List
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button("📷 Ajouter Photos") {
                    showingImagePicker = true
                }
                .buttonStyle(.borderedProminent)
                
                Button("📁 Galerie") {
                    showingGallery = true
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Text("\(photos.count) photo(s)")
                    .foregroundColor(.secondary)
                
                Picker("Vue", selection: $viewMode) {
                    Image(systemName: "grid").tag(0)
                    Image(systemName: "list.bullet").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 80)
                
                if !selectedPhotos.isEmpty {
                    Button("🗑️ Supprimer (\(selectedPhotos.count))") {
                        deleteSelectedPhotos()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            .padding()
            
            Divider()
            
            // Contenu selon le mode de vue
            if viewMode == 0 {
                PhotoGridView(
                    photos: photos,
                    selectedPhotos: $selectedPhotos,
                    selectedPhoto: $selectedPhoto,
                    showingDetail: $showingPhotoDetail
                )
            } else {
                PhotoListView(
                    photos: photos,
                    selectedPhotos: $selectedPhotos,
                    selectedPhoto: $selectedPhoto,
                    showingDetail: $showingPhotoDetail
                )
            }
        }
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            handleImageSelection(result)
        }
        .sheet(isPresented: $showingPhotoDetail) {
            if let photo = selectedPhoto {
                PhotoDetailView(photo: photo, document: document)
            }
        }
    }
    
    private var photos: [SitePhoto] {
        // Pour l'instant, on simule avec des données factices
        // Dans une vraie implémentation, ceci viendrait de Core Data
        return []
    }
    
    private func handleImageSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            importPhotos(from: urls)
        case .failure(let error):
            print("Erreur sélection image: \(error)")
        }
    }
    
    private func importPhotos(from urls: [URL]) {
        for url in urls {
            createSitePhoto(from: url)
        }
    }
    
    private func createSitePhoto(from url: URL) {
        // Implémentation de l'import de photo
        // Pour l'instant simulé
        print("Import photo: \(url.lastPathComponent)")
    }
    
    private func deleteSelectedPhotos() {
        // Implémentation de la suppression
        selectedPhotos.removeAll()
    }
}

// MARK: - Site Photo Model (Simulé)
struct SitePhoto: Identifiable, Hashable {
    let id = UUID()
    let filename: String
    let captureDate: Date
    let location: String?
    let category: PhotoCategory
    let corpsEtat: CorpsEtat?
    let notes: String?
    let thumbnailData: Data?
    let fullImageData: Data?
    
    enum PhotoCategory: String, CaseIterable, Codable {
        case avant = "Avant travaux"
        case pendant = "En cours"
        case apres = "Après travaux"
        case probleme = "Problème"
        case detail = "Détail technique"
        case livraison = "Livraison"
        
        var icon: String {
            switch self {
            case .avant: return "camera.badge.ellipsis"
            case .pendant: return "hammer.circle"
            case .apres: return "checkmark.circle"
            case .probleme: return "exclamationmark.triangle"
            case .detail: return "magnifyingglass.circle"
            case .livraison: return "shippingbox"
            }
        }
        
        var color: Color {
            switch self {
            case .avant: return .blue
            case .pendant: return .orange
            case .apres: return .green
            case .probleme: return .red
            case .detail: return .purple
            case .livraison: return .brown
            }
        }
    }
}

// MARK: - Photo Grid View
struct PhotoGridView: View {
    let photos: [SitePhoto]
    @Binding var selectedPhotos: Set<SitePhoto>
    @Binding var selectedPhoto: SitePhoto?
    @Binding var showingDetail: Bool
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 4)
    
    var body: some View {
        ScrollView {
            if photos.isEmpty {
                EmptyPhotosView()
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(photos) { photo in
                        PhotoGridCard(
                            photo: photo,
                            isSelected: selectedPhotos.contains(photo)
                        ) { action in
                            handlePhotoAction(photo: photo, action: action)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private func handlePhotoAction(photo: SitePhoto, action: PhotoAction) {
        switch action {
        case .select:
            if selectedPhotos.contains(photo) {
                selectedPhotos.remove(photo)
            } else {
                selectedPhotos.insert(photo)
            }
        case .view:
            selectedPhoto = photo
            showingDetail = true
        }
    }
}

enum PhotoAction {
    case select, view
}

struct PhotoGridCard: View {
    let photo: SitePhoto
    let isSelected: Bool
    let onAction: (PhotoAction) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Image
            ZStack {
                Rectangle()
                    .fill(Color(.controlBackgroundColor))
                    .aspectRatio(4/3, contentMode: .fit)
                
                if let thumbnailData = photo.thumbnailData,
                   let nsImage = NSImage(data: thumbnailData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Text("Image indisponible")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Overlays
                VStack {
                    HStack {
                        // Sélection
                        Button(action: { onAction(.select) }) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isSelected ? .white : .gray)
                                .background(
                                    Circle()
                                        .fill(isSelected ? Color.blue : Color.clear)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        // Catégorie
                        Label(photo.category.rawValue, systemImage: photo.category.icon)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(photo.category.color.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    // Corps d'état si défini
                    if let corpsEtat = photo.corpsEtat {
                        HStack {
                            Spacer()
                            Text(corpsEtat.localized)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(corpsEtat.color.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(8)
            }
            .onTapGesture {
                onAction(.view)
            }
            
            // Informations
            VStack(alignment: .leading, spacing: 2) {
                Text(photo.filename)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(photo.captureDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let location = photo.location {
                    Text("📍 \(location)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Photo List View
struct PhotoListView: View {
    let photos: [SitePhoto]
    @Binding var selectedPhotos: Set<SitePhoto>
    @Binding var selectedPhoto: SitePhoto?
    @Binding var showingDetail: Bool
    
    var body: some View {
        ScrollView {
            if photos.isEmpty {
                EmptyPhotosView()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(photos) { photo in
                        PhotoListRow(
                            photo: photo,
                            isSelected: selectedPhotos.contains(photo)
                        ) { action in
                            handlePhotoAction(photo: photo, action: action)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private func handlePhotoAction(photo: SitePhoto, action: PhotoAction) {
        switch action {
        case .select:
            if selectedPhotos.contains(photo) {
                selectedPhotos.remove(photo)
            } else {
                selectedPhotos.insert(photo)
            }
        case .view:
            selectedPhoto = photo
            showingDetail = true
        }
    }
}

struct PhotoListRow: View {
    let photo: SitePhoto
    let isSelected: Bool
    let onAction: (PhotoAction) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Sélection
            Button(action: { onAction(.select) }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Miniature
            Rectangle()
                .fill(Color(.controlBackgroundColor))
                .frame(width: 60, height: 45)
                .cornerRadius(4)
                .overlay(
                    Group {
                        if let thumbnailData = photo.thumbnailData,
                           let nsImage = NSImage(data: thumbnailData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                        } else {
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        }
                    }
                )
            
            // Informations
            VStack(alignment: .leading, spacing: 4) {
                Text(photo.filename)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack {
                    Label(photo.category.rawValue, systemImage: photo.category.icon)
                        .font(.caption)
                        .foregroundColor(photo.category.color)
                    
                    if let corpsEtat = photo.corpsEtat {
                        Text("• \(corpsEtat.localized)")
                            .font(.caption)
                            .foregroundColor(corpsEtat.color)
                    }
                }
                
                Text(photo.captureDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let location = photo.location {
                    Text("📍 \(location)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Actions
            Button(action: { onAction(.view) }) {
                Image(systemName: "eye")
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Empty Photos View
struct EmptyPhotosView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Aucune photo")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Ajoutez des photos de chantier pour documenter l'avancement des travaux")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("📷 Ajouter vos premières photos") {
                // Action d'ajout
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Photo Detail View
struct PhotoDetailView: View {
    let photo: SitePhoto
    @ObservedObject var document: Document
    @Environment(\.presentationMode) var presentationMode
    
    @State private var editedNotes: String
    @State private var editedCategory: SitePhoto.PhotoCategory
    @State private var editedCorpsEtat: CorpsEtat?
    @State private var editedLocation: String
    
    init(photo: SitePhoto, document: Document) {
        self.photo = photo
        self.document = document
        self._editedNotes = State(initialValue: photo.notes ?? "")
        self._editedCategory = State(initialValue: photo.category)
        self._editedCorpsEtat = State(initialValue: photo.corpsEtat)
        self._editedLocation = State(initialValue: photo.location ?? "")
    }
    
    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                // Image
                VStack {
                    if let imageData = photo.fullImageData,
                       let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 500)
                    } else {
                        Rectangle()
                            .fill(Color(.controlBackgroundColor))
                            .aspectRatio(4/3, contentMode: .fit)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 60))
                                        .foregroundColor(.secondary)
                                    Text("Image indisponible")
                                        .foregroundColor(.secondary)
                                }
                            )
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                // Détails et édition
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Informations")
                            .font(.headline)
                        
                        InfoRow(label: "Fichier", value: photo.filename)
                        InfoRow(label: "Date", value: photo.captureDate.formatted(date: .abbreviated, time: .shortened))
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Classification")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Catégorie:")
                                .font(.subheadline)
                            
                            Picker("Catégorie", selection: $editedCategory) {
                                ForEach(SitePhoto.PhotoCategory.allCases, id: \.self) { category in
                                    Label(category.rawValue, systemImage: category.icon)
                                        .tag(category)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Corps d'état:")
                                .font(.subheadline)
                            
                            Picker("Corps d'état", selection: $editedCorpsEtat) {
                                Text("Aucun").tag(nil as CorpsEtat?)
                                ForEach(CorpsEtat.allCases, id: \.self) { corps in
                                    Text(corps.localized).tag(corps as CorpsEtat?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Localisation:")
                                .font(.subheadline)
                            
                            TextField("Localisation sur le chantier", text: $editedLocation)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        
                        TextEditor(text: $editedNotes)
                            .frame(minHeight: 100)
                            .border(Color(.controlBackgroundColor))
                    }
                    
                    Spacer()
                }
                .frame(width: 300)
                .padding()
            }
            .navigationTitle("Détails Photo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Enregistrer") {
                        saveChanges()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(width: 800, height: 600)
    }
    
    private func saveChanges() {
        // Implémentation de la sauvegarde
        print("Sauvegarde des modifications pour \(photo.filename)")
        presentationMode.wrappedValue.dismiss()
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label):")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
        }
    }
}

// MARK: - Site Photo Gallery View
struct SitePhotoGalleryView: View {
    @ObservedObject var document: Document
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Galerie complète des photos de chantier")
                    .font(.title2)
                    .padding()
                
                // Implémentation de la galerie complète
                Spacer()
                
                Text("Fonctionnalité en développement")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Galerie Photos")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let document = Document(context: context)
    
    return PhotosTab(document: document, showingGallery: .constant(false))
        .environment(\.managedObjectContext, context)
        .frame(width: 900, height: 600)
}