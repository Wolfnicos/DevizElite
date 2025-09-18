import SwiftUI
import AVFoundation
import Speech

// MARK: - Interface Chat Améliorée
struct IntelligentChatView: View {
    @StateObject private var bot = BTPIntelligentBot()
    @ObservedObject var document: Document
    @State private var message = ""
    @State private var isRecording = false
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var showingPriceSearch = false
    @State private var showingAnalysisDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            chatHeader
            
            // Messages
            messagesScrollView
            
            // Quick Actions
            quickActionsBar
            
            // Input
            messageInputBar
        }
        .navigationTitle("🤖 Assistant BTP")
        .onAppear {
            // Speech recognition temporarily disabled until privacy permissions are configured
            print("AI Chat loaded - voice input disabled until permissions added to Info.plist")
        }
    }
    
    // MARK: - Chat Header
    private var chatHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Assistant BTP Intelligent")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("En ligne")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Document context indicator
            if document.number != nil {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Contexte:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(document.type == "invoice" ? "📄 Facture" : "📋 Devis")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(document.type == "invoice" ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top)
    }
    
    // MARK: - Messages Scroll View
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(bot.messages) { msg in
                        ChatBubbleView(message: msg, document: document)
                            .id(msg.id)
                    }
                    
                    if bot.isLoading {
                        LoadingIndicatorView()
                            .id("loading")
                    }
                }
                .padding()
                .onChange(of: bot.messages.count) { _, _ in
                    if let lastMessage = bot.messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: bot.isLoading) { _, _ in
                    if bot.isLoading {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Actions Bar
    private var quickActionsBar: some View {
        VStack(spacing: 8) {
            // Première rangée
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "eurosign.circle.fill",
                    title: "Prix actuels",
                    color: .green
                ) {
                    Task {
                        await bot.processMessage("Recherche les prix actuels des matériaux de construction", context: document)
                    }
                }
                
                QuickActionButton(
                    icon: "chart.bar.doc.horizontal.fill",
                    title: "Analyser document",
                    color: .blue
                ) {
                    Task {
                        await bot.processMessage("Analyse en détail ce document et détecte les anomalies", context: document)
                    }
                }
                
                QuickActionButton(
                    icon: "building.2.crop.circle.fill",
                    title: "Comparer fournisseurs",
                    color: .purple
                ) {
                    Task {
                        await bot.processMessage("Compare les fournisseurs pour ces articles", context: document)
                    }
                }
            }
            
            // Deuxième rangée
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    title: "Tendances marché",
                    color: .orange
                ) {
                    Task {
                        await bot.processMessage("Quelles sont les tendances du marché BTP en 2025?", context: document)
                    }
                }
                
                QuickActionButton(
                    icon: "lightbulb.circle.fill",
                    title: "Optimiser",
                    color: .yellow
                ) {
                    Task {
                        await bot.processMessage("Comment optimiser ce projet pour réduire les coûts?", context: document)
                    }
                }
                
                QuickActionButton(
                    icon: "percent.circle.fill",
                    title: "TVA & Taxes",
                    color: .red
                ) {
                    Task {
                        await bot.processMessage("Vérifie la TVA et donne des conseils fiscaux", context: document)
                    }
                }
            }
            
            // Troisième rangée - ChatGPT
            HStack(spacing: 12) {
                Spacer()
                
                QuickActionButton(
                    icon: "brain.head.profile.fill",
                    title: "🤖 ChatGPT",
                    color: .green
                ) {
                    Task {
                        await bot.processMessage("[GPT] Expert BTP: analysez tout ce document et donnez conseils détaillés", context: document)
                    }
                }
                
                QuickActionButton(
                    icon: "message.circle.fill",
                    title: "💬 Chat IA",
                    color: .mint
                ) {
                    Task {
                        await bot.processMessage("[GPT] Mode conversation libre - posez votre question BTP", context: document)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.controlBackgroundColor))
    }
    
    // MARK: - Message Input Bar
    private var messageInputBar: some View {
        HStack(spacing: 8) {
            // Voice input button - disabled until permissions are properly configured
            Button(action: {
                // Temporarily disabled to prevent privacy crash
                print("Voice input temporarily disabled - requires Info.plist privacy permissions")
            }) {
                Image(systemName: "mic.slash.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(8)
            .background(Circle().fill(Color(.controlBackgroundColor)))
            .disabled(true)
            
            // Text input
            HStack {
                TextField("Demandez prix, analyse, suggestions...", text: $message, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .lineLimit(1...4)
                    .onSubmit { sendMessage() }
                
                if !message.isEmpty {
                    Button(action: { message = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.controlBackgroundColor))
                    .stroke(Color(.separatorColor), lineWidth: 0.5)
            )
            
            // Send button
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(8)
            .background(
                Circle()
                    .fill(message.isEmpty && !isRecording ? Color.gray : Color.accentColor)
            )
            .disabled(message.isEmpty && !isRecording)
            .scaleEffect(message.isEmpty && !isRecording ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: message.isEmpty)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
    }
    
    // MARK: - Actions
    private func sendMessage() {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let messageToSend = message
        message = ""
        
        Task {
            await bot.processMessage(messageToSend, context: document)
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        // Check authorization first
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            print("Speech recognition not authorized")
            return
        }
        
        isRecording = true
        speechRecognizer.startRecording { transcript in
            DispatchQueue.main.async {
                message = transcript
            }
        }
    }
    
    private func stopRecording() {
        isRecording = false
        speechRecognizer.stopRecording()
        
        if !message.isEmpty {
            sendMessage()
        }
    }
    
    private func setupSpeechRecognition() {
        #if os(macOS)
        // Check if speech recognition is available first
        guard speechRecognizer.speechRecognizer?.isAvailable == true else {
            print("Speech recognition not available")
            return
        }
        
        // Request permission with proper handling
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    print("Speech recognition denied by user")
                case .restricted:
                    print("Speech recognition restricted on this device")
                case .notDetermined:
                    print("Speech recognition not determined")
                @unknown default:
                    print("Unknown speech recognition authorization status")
                }
            }
        }
        #endif
    }
}

// MARK: - Chat Bubble View
struct ChatBubbleView: View {
    let message: ChatMessage
    let document: Document
    
    var body: some View {
        HStack {
            if message.isBot {
                botMessageView
                Spacer(minLength: 50)
            } else {
                Spacer(minLength: 50)
                userMessageView
            }
        }
    }
    
    private var botMessageView: some View {
        HStack(alignment: .top, spacing: 8) {
            // Bot avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 32, height: 32)
                
                Text("🤖")
                    .font(.system(size: 16))
            }
            
            // Message content
            VStack(alignment: .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                
                // Message actions
                if message.type != .welcome {
                    messageActionsView
                }
                
                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.controlBackgroundColor))
                    .stroke(Color(.separatorColor), lineWidth: 0.5)
            )
        }
    }
    
    private var userMessageView: some View {
        HStack(alignment: .top, spacing: 8) {
            // Message content
            VStack(alignment: .trailing, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.accentColor)
            )
            
            // User avatar
            Circle()
                .fill(Color(.controlColor))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                )
        }
    }
    
    private var messageActionsView: some View {
        HStack(spacing: 8) {
            if message.type == .priceSearch {
                Button("🔍 Détails prix") {
                    // Action pour voir détails prix
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
            }
            
            if message.type == .documentAnalysis {
                Button("📊 Voir analyse") {
                    // Action pour voir analyse détaillée
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .cornerRadius(8)
            }
            
            Button("💬 Continuer") {
                // Action pour continuer la conversation
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 120, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) {
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
}

// MARK: - Loading Indicator
struct LoadingIndicatorView: View {
    @State private var animateGradient = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Bot avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 32, height: 32)
                
                Text("🤖")
                    .font(.system(size: 16))
            }
            
            // Typing indicator
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animateGradient ? 1.0 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animateGradient
                        )
                }
                
                Text("Assistant réfléchit...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.controlBackgroundColor))
                    .stroke(Color(.separatorColor), lineWidth: 0.5)
            )
            
            Spacer()
        }
        .onAppear {
            animateGradient = true
        }
    }
}

// MARK: - Speech Recognizer
class SpeechRecognizer: ObservableObject {
    var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied, .restricted, .notDetermined:
                    print("Speech recognition not authorized")
                @unknown default:
                    break
                }
            }
        }
    }
    
    func startRecording(completion: @escaping (String) -> Void) {
        // Check authorization first
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            print("Speech recognition not authorized. Status: \(SFSpeechRecognizer.authorizationStatus().rawValue)")
            return
        }
        
        // Cancel any previous task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest,
              let speechRecognizer = self.speechRecognizer,
              speechRecognizer.isAvailable else { 
            print("Speech recognition not available")
            return 
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                completion(result.bestTranscription.formattedString)
            }
            
            if error != nil {
                self.stopRecording()
            }
        }
        
        // Configure audio session - macOS compatible
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        #endif
        
        // Start audio engine
        do {
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print("Audio engine failed to start: \(error)")
            return
        }
    }
    
    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
    }
}