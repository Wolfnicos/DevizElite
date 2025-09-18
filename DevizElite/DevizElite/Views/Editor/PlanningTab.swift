import SwiftUI
import CoreData

struct PlanningTab: View {
    @ObservedObject var document: Document
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedView = 0 // 0: Timeline, 1: Calendar, 2: Gantt
    @State private var showingPhaseEditor = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Picker("Vue", selection: $selectedView) {
                    Text("Timeline").tag(0)
                    Text("Calendrier").tag(1)
                    Text("Diagramme").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 250)
                
                Spacer()
                
                Button("📝 Ajouter Phase") {
                    showingPhaseEditor = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // Contenu selon la vue sélectionnée
            switch selectedView {
            case 0:
                TimelineView(document: document)
            case 1:
                CalendarView(document: document)
            case 2:
                GanttView(document: document)
            default:
                TimelineView(document: document)
            }
        }
        .sheet(isPresented: $showingPhaseEditor) {
            PhaseEditorView(document: document)
        }
    }
}

// MARK: - Timeline View
struct TimelineView: View {
    @ObservedObject var document: Document
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Informations générales du projet
                ProjectTimelineHeader(document: document)
                
                // Timeline des phases
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(timelineItems, id: \.id) { item in
                        TimelineItemView(item: item)
                    }
                }
                .padding(.leading, 20)
            }
            .padding()
        }
    }
    
    private var timelineItems: [TimelineItem] {
        var items: [TimelineItem] = []
        
        // Ajout des dates du projet
        if let startDate = document.projectStartDate {
            items.append(TimelineItem(
                id: UUID(),
                title: "🚀 Début du projet",
                date: startDate,
                type: .milestone,
                description: document.projectName,
                corpsEtat: nil
            ))
        }
        
        // Ajout des lignes avec dates
        if let lineItems = document.lineItems?.allObjects as? [LineItem] {
            for lineItem in lineItems {
                if let startDate = lineItem.workStartDate {
                    items.append(TimelineItem(
                        id: lineItem.id ?? UUID(),
                        title: lineItem.corpsEtat?.localized ?? "Travaux",
                        date: startDate,
                        type: .workStart,
                        description: lineItem.itemDescription,
                        corpsEtat: lineItem.corpsEtat
                    ))
                }
                
                if let endDate = lineItem.workEndDate {
                    items.append(TimelineItem(
                        id: UUID(),
                        title: "✅ Fin \(lineItem.corpsEtat?.localized ?? "travaux")",
                        date: endDate,
                        type: .workEnd,
                        description: lineItem.itemDescription,
                        corpsEtat: lineItem.corpsEtat
                    ))
                }
            }
        }
        
        // Ajout de la fin du projet
        if let endDate = document.projectEndDate {
            items.append(TimelineItem(
                id: UUID(),
                title: "🏁 Fin du projet",
                date: endDate,
                type: .milestone,
                description: "Livraison finale",
                corpsEtat: nil
            ))
        }
        
        return items.sorted { $0.date < $1.date }
    }
}

// MARK: - Timeline Item
struct TimelineItem {
    let id: UUID
    let title: String
    let date: Date
    let type: TimelineItemType
    let description: String?
    let corpsEtat: CorpsEtat?
    
    enum TimelineItemType {
        case milestone, workStart, workEnd
        
        var icon: String {
            switch self {
            case .milestone: return "flag.fill"
            case .workStart: return "play.circle.fill"
            case .workEnd: return "checkmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .milestone: return .blue
            case .workStart: return .green
            case .workEnd: return .orange
            }
        }
    }
}

struct ProjectTimelineHeader: View {
    @ObservedObject var document: Document
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Planning du Projet")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let projectName = document.projectName {
                        Text(projectName)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                // Statistiques du planning
                VStack(alignment: .trailing, spacing: 4) {
                    if let duration = projectDuration {
                        Text("\(duration) jours")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Text("Durée prévue")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Barre de progression
            if let progress = projectProgress {
                ProgressView(value: progress) {
                    Text("Avancement: \(Int(progress * 100))%")
                        .font(.caption)
                }
                .progressViewStyle(LinearProgressViewStyle())
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var projectDuration: Int? {
        guard let start = document.projectStartDate,
              let end = document.projectEndDate else { return nil }
        
        return Calendar.current.dateComponents([.day], from: start, to: end).day
    }
    
    private var projectProgress: Double? {
        guard let lineItems = document.lineItems?.allObjects as? [LineItem],
              !lineItems.isEmpty else { return nil }
        
        let completedItems = lineItems.filter { $0.isCompleted }.count
        return Double(completedItems) / Double(lineItems.count)
    }
}

struct TimelineItemView: View {
    let item: TimelineItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(item.type.color)
                    .frame(width: 12, height: 12)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2, height: 40)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: item.type.icon)
                        .foregroundColor(item.type.color)
                    
                    Text(item.title)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(item.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let description = item.description {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                if let corpsEtat = item.corpsEtat {
                    HStack {
                        Image(systemName: corpsEtat.icon)
                            .foregroundColor(corpsEtat.color)
                        
                        Text(corpsEtat.category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(corpsEtat.color.opacity(0.2))
                            .foregroundColor(corpsEtat.color)
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Calendar View
struct CalendarView: View {
    @ObservedObject var document: Document
    @State private var selectedDate = Date()
    
    var body: some View {
        HStack(spacing: 0) {
            // Calendrier
            VStack {
                DatePicker(
                    "Sélectionner une date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                
                Spacer()
            }
            .frame(width: 350)
            
            Divider()
            
            // Détails du jour sélectionné
            VStack(alignment: .leading, spacing: 16) {
                Text("Activités du \(selectedDate, formatter: dateFormatter)")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(activitiesForDate(selectedDate), id: \.id) { activity in
                            CalendarActivityView(activity: activity)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }
    
    private func activitiesForDate(_ date: Date) -> [CalendarActivity] {
        var activities: [CalendarActivity] = []
        
        let calendar = Calendar.current
        
        // Vérifier les dates du projet
        if let startDate = document.projectStartDate,
           calendar.isDate(date, inSameDayAs: startDate) {
            activities.append(CalendarActivity(
                id: UUID(),
                title: "Début du projet",
                type: .milestone,
                corpsEtat: nil
            ))
        }
        
        if let endDate = document.projectEndDate,
           calendar.isDate(date, inSameDayAs: endDate) {
            activities.append(CalendarActivity(
                id: UUID(),
                title: "Fin du projet",
                type: .milestone,
                corpsEtat: nil
            ))
        }
        
        // Vérifier les activités des lignes
        if let lineItems = document.lineItems?.allObjects as? [LineItem] {
            for lineItem in lineItems {
                if let startDate = lineItem.workStartDate,
                   calendar.isDate(date, inSameDayAs: startDate) {
                    activities.append(CalendarActivity(
                        id: lineItem.id ?? UUID(),
                        title: "Début: \(lineItem.itemDescription ?? "")",
                        type: .workStart,
                        corpsEtat: lineItem.corpsEtat
                    ))
                }
                
                if let endDate = lineItem.workEndDate,
                   calendar.isDate(date, inSameDayAs: endDate) {
                    activities.append(CalendarActivity(
                        id: UUID(),
                        title: "Fin: \(lineItem.itemDescription ?? "")",
                        type: .workEnd,
                        corpsEtat: lineItem.corpsEtat
                    ))
                }
            }
        }
        
        return activities
    }
}

struct CalendarActivity {
    let id: UUID
    let title: String
    let type: TimelineItem.TimelineItemType
    let corpsEtat: CorpsEtat?
}

struct CalendarActivityView: View {
    let activity: CalendarActivity
    
    var body: some View {
        HStack {
            Image(systemName: activity.type.icon)
                .foregroundColor(activity.type.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.body)
                
                if let corpsEtat = activity.corpsEtat {
                    Text(corpsEtat.localized)
                        .font(.caption)
                        .foregroundColor(corpsEtat.color)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Gantt View
struct GanttView: View {
    @ObservedObject var document: Document
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                // En-tête avec les dates
                GanttHeader(document: document)
                
                // Lignes du diagramme
                ForEach(ganttItems, id: \.id) { item in
                    GanttRow(item: item, document: document)
                }
            }
        }
        .padding()
    }
    
    private var ganttItems: [GanttItem] {
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else { return [] }
        
        return lineItems.compactMap { lineItem in
            guard let startDate = lineItem.workStartDate,
                  let endDate = lineItem.workEndDate else { return nil }
            
            return GanttItem(
                id: lineItem.id ?? UUID(),
                title: lineItem.itemDescription ?? "",
                startDate: startDate,
                endDate: endDate,
                corpsEtat: lineItem.corpsEtat,
                isCompleted: lineItem.isCompleted
            )
        }.sorted { $0.startDate < $1.startDate }
    }
}

struct GanttItem {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let corpsEtat: CorpsEtat?
    let isCompleted: Bool
}

struct GanttHeader: View {
    @ObservedObject var document: Document
    
    var body: some View {
        HStack {
            Text("Tâches")
                .font(.headline)
                .frame(width: 200, alignment: .leading)
            
            // Dates header (simplified for now)
            ScrollView(.horizontal) {
                HStack {
                    ForEach(dateRange, id: \.self) { date in
                        Text(date, formatter: dayFormatter)
                            .font(.caption)
                            .frame(width: 30)
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    private var dateRange: [Date] {
        guard let start = document.projectStartDate,
              let end = document.projectEndDate else { return [] }
        
        var dates: [Date] = []
        var currentDate = start
        
        while currentDate <= end {
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter
    }
}

struct GanttRow: View {
    let item: GanttItem
    @ObservedObject var document: Document
    
    var body: some View {
        HStack {
            // Titre de la tâche
            HStack {
                if let corpsEtat = item.corpsEtat {
                    Image(systemName: corpsEtat.icon)
                        .foregroundColor(corpsEtat.color)
                }
                
                Text(item.title)
                    .font(.body)
                    .lineLimit(1)
            }
            .frame(width: 200, alignment: .leading)
            
            // Barre de progression (simplifiée)
            Rectangle()
                .fill(item.corpsEtat?.color ?? Color.blue)
                .opacity(item.isCompleted ? 1.0 : 0.6)
                .frame(height: 20)
                .overlay(
                    Rectangle()
                        .stroke(Color.primary, lineWidth: item.isCompleted ? 2 : 1)
                )
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Phase Editor
struct PhaseEditorView: View {
    @ObservedObject var document: Document
    @Environment(\.presentationMode) var presentationMode
    
    @State private var phaseName = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Nom de la phase", text: $phaseName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                DatePicker("Date de début", selection: $startDate, displayedComponents: .date)
                
                DatePicker("Date de fin", selection: $endDate, displayedComponents: .date)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Nouvelle Phase")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Ajouter") {
                        addPhase()
                    }
                    .disabled(phaseName.isEmpty)
                }
            }
        }
    }
    
    private func addPhase() {
        // Cette fonctionnalité sera étendue plus tard
        document.projectPhase = phaseName
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let document = Document(context: context)
    document.projectStartDate = Date()
    document.projectEndDate = Calendar.current.date(byAdding: .month, value: 2, to: Date())
    
    return PlanningTab(document: document)
        .environment(\.managedObjectContext, context)
        .frame(width: 900, height: 600)
}