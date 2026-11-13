import SwiftUI

struct ContentView: View {
    @StateObject private var weatherService = WeatherService()
    @StateObject private var pcService = PCTelemetryService()
    
    @State private var currentTime = Date()
    @State private var promptText = ""
    @State private var isNightMode = false
    @State private var showSettings = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Fundo
            (isNightMode ? Color.black : Color(red: 0.07, green: 0.08, blue: 0.11))
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Top Bar
                HStack(spacing: 16) {
                    Label("Cockpit IA", systemImage: "terminal.fill")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(accentColor)
                    
                    // Status PC
                    HStack(spacing: 6) {
                        Circle()
                            .fill(pcService.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(pcService.isConnected ? "PC Conectado (\(pcService.host))" : "PC Desconectado")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(secondaryTextColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(cardBackground)
                    .cornerRadius(12)
                    .onTapGesture {
                        showSettings.toggle()
                    }
                    
                    Spacer()
                    
                    // Relógio no topo
                    Text(timeString(from: currentTime))
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundColor(textColor)
                    
                    // Alternar Modo Noturno
                    Button(action: { withAnimation { isNightMode.toggle() } }) {
                        Image(systemName: isNightMode ? "moon.fill" : "sun.max.fill")
                            .font(.system(size: 15))
                            .foregroundColor(isNightMode ? .red : .yellow)
                            .padding(8)
                            .background(cardBackground)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Área Principal com 3 Colunas em Paisagem
                HStack(alignment: .top, spacing: 14) {
                    // Coluna 1: Antigravity Remote
                    AntigravityColumn(pcService: pcService,
                                      promptText: $promptText,
                                      cardBackground: cardBackground,
                                      textColor: textColor,
                                      secondaryTextColor: secondaryTextColor,
                                      accentColor: accentColor)
                        .frame(maxWidth: .infinity)
                    
                    // Coluna 2: ChatGPT Remote
                    ChatGPTColumn(cardBackground: cardBackground,
                                  textColor: textColor,
                                  secondaryTextColor: secondaryTextColor)
                        .frame(maxWidth: .infinity)
                    
                    // Coluna 3: Telemetria, Clima & Controles
                    InfoHubColumn(weatherService: weatherService,
                                  pcService: pcService,
                                  currentTime: currentTime,
                                  isNightMode: $isNightMode,
                                  cardBackground: cardBackground,
                                  textColor: textColor,
                                  secondaryTextColor: secondaryTextColor,
                                  accentColor: accentColor)
                        .frame(width: 310)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
        .onReceive(timer) { input in
            currentTime = input
        }
        .task {
            await weatherService.fetchWeather()
            await pcService.fetchTelemetry()
        }
        .sheet(isPresented: $showSettings) {
            PCSettingsView(pcService: pcService)
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
    
    private var cardBackground: Color {
        isNightMode ? Color(white: 0.08) : Color(red: 0.13, green: 0.14, blue: 0.19)
    }
    private var textColor: Color {
        isNightMode ? Color(red: 0.95, green: 0.3, blue: 0.25) : .white
    }
    private var secondaryTextColor: Color {
        isNightMode ? Color(red: 0.70, green: 0.2, blue: 0.15) : Color(white: 0.65)
    }
    private var accentColor: Color {
        isNightMode ? Color(red: 0.90, green: 0.25, blue: 0.20) : Color(red: 0.35, green: 0.65, blue: 1.0)
    }
}

// MARK: - Coluna 1: Antigravity
struct AntigravityColumn: View {
    @ObservedObject var pcService: PCTelemetryService
    @Binding var promptText: String
    let cardBackground: Color
    let textColor: Color
    let secondaryTextColor: Color
    let accentColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            // Header da coluna
            HStack {
                Label("Antigravity Agent", systemImage: "cpu")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                Spacer()
                AgentStatusBadge(status: pcService.agentStatus)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            
            // Log / Mensagem do agente
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(pcService.agentMessage)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(textColor.opacity(0.9))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(Color.black.opacity(0.3))
            .cornerRadius(14)
            .padding(.horizontal, 14)
            
            // Caixa de aprovação pendente (se houver)
            if let pending = pcService.pendingApproval {
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundColor(.yellow)
                        Text("Aprovação Solicitada")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    Text(pending)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(white: 0.9))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 10) {
                        Button(action: { Task { await pcService.respondApproval(approved: true) } }) {
                            Text("Aprovar")
                                .font(.system(size: 13, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        Button(action: { Task { await pcService.respondApproval(approved: false) } }) {
                            Text("Recusar")
                                .font(.system(size: 13, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(12)
                .background(Color.yellow.opacity(0.15))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.yellow.opacity(0.4), lineWidth: 1))
                .cornerRadius(14)
                .padding(.horizontal, 14)
            }
            
            // Campo de envio de prompt
            HStack(spacing: 8) {
                TextField("Enviar comando ao Antigravity...", text: $promptText)
                    .font(.system(size: 13))
                    .padding(10)
                    .background(Color.black.opacity(0.25))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                
                Button(action: {
                    let text = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    Task {
                        let ok = await pcService.sendPrompt(text)
                        if ok { promptText = "" }
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(accentColor)
                }
                .disabled(promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pcService.isSending)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(cardBackground)
        .cornerRadius(20)
    }
}

// MARK: - Coluna 2: ChatGPT
struct ChatGPTColumn: View {
    let cardBackground: Color
    let textColor: Color
    let secondaryTextColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("ChatGPT", systemImage: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                Spacer()
                Text("Web Autenticado")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(secondaryTextColor)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            
            // WebView incorporada
            ChatGPTWebView()
                .cornerRadius(14)
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
        }
        .background(cardBackground)
        .cornerRadius(20)
    }
}

// MARK: - Coluna 3: Telemetria & Clima
struct InfoHubColumn: View {
    @ObservedObject var weatherService: WeatherService
    @ObservedObject var pcService: PCTelemetryService
    let currentTime: Date
    @Binding var isNightMode: Bool
    let cardBackground: Color
    let textColor: Color
    let secondaryTextColor: Color
    let accentColor: Color
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                // Card de Clima
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("CLIMA")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(secondaryTextColor)
                        Spacer()
                        Image(systemName: weatherService.conditionIcon)
                            .foregroundColor(.orange)
                    }
                    HStack(alignment: .firstTextBaseline) {
                        Text(String(format: "%.0f°", weatherService.temperature))
                            .font(.system(size: 38, weight: .medium, design: .rounded))
                            .foregroundColor(textColor)
                        Spacer()
                        Text(weatherService.conditionText)
                            .font(.system(size: 13))
                            .foregroundColor(secondaryTextColor)
                    }
                    Text("Sensação: \(String(format: "%.0f°", weatherService.apparentTemp)) • Umidade: \(weatherService.humidity)%")
                        .font(.system(size: 11))
                        .foregroundColor(secondaryTextColor)
                }
                .padding(14)
                .background(cardBackground)
                .cornerRadius(18)
                
                // Card de Telemetria do PC
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("TELEMETRIA WINDOWS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(secondaryTextColor)
                        Spacer()
                        Image(systemName: "desktopcomputer")
                            .foregroundColor(accentColor)
                    }
                    
                    // CPU
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("CPU")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(textColor)
                            Spacer()
                            Text(String(format: "%.0f%%", pcService.cpuUsage))
                                .font(.system(size: 12, weight: .monospaced))
                                .foregroundColor(textColor)
                        }
                        ProgressView(value: min(max(pcService.cpuUsage / 100.0, 0), 1))
                            .tint(accentColor)
                    }
                    
                    // RAM
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("RAM")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(textColor)
                            Spacer()
                            Text(String(format: "%.1f / %.0f GB", pcService.ramUsedGB, pcService.ramTotalGB))
                                .font(.system(size: 12, weight: .monospaced))
                                .foregroundColor(textColor)
                        }
                        ProgressView(value: min(max(pcService.ramPercent / 100.0, 0), 1))
                            .tint(accentColor)
                    }
                }
                .padding(14)
                .background(cardBackground)
                .cornerRadius(18)
                
                // Atalhos de Ação Rápida
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button(action: { Task { await pcService.triggerMediaAction("mute") } }) {
                            Label("Mudo", systemImage: "speaker.slash.fill")
                                .font(.system(size: 12, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.08))
                                .foregroundColor(textColor)
                                .cornerRadius(12)
                        }
                        Button(action: { Task { await pcService.triggerMediaAction("playpause") } }) {
                            Label("Mídia", systemImage: "playpause.fill")
                                .font(.system(size: 12, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.08))
                                .foregroundColor(textColor)
                                .cornerRadius(12)
                        }
                    }
                    
                    Button(action: { Task { await weatherService.fetchWeather() } }) {
                        Label("Atualizar Dados", systemImage: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(textColor)
                            .cornerRadius(12)
                    }
                }
                .padding(14)
                .background(cardBackground)
                .cornerRadius(18)
            }
        }
    }
}

// Badge de Status do Agente
struct AgentStatusBadge: View {
    let status: String
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(badgeColor)
                .frame(width: 7, height: 7)
            Text(statusTitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(badgeColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeColor.opacity(0.15))
        .cornerRadius(10)
    }
    
    private var statusTitle: String {
        switch status {
        case "working": return "Trabalhando"
        case "waiting_approval": return "Aguardando"
        default: return "Ocioso"
        }
    }
    
    private var badgeColor: Color {
        switch status {
        case "working": return .blue
        case "waiting_approval": return .yellow
        default: return .green
        }
    }
}

// Modal de Configuração do IP do PC
struct PCSettingsView: View {
    @ObservedObject var pcService: PCTelemetryService
    @Environment(\.presentationMode) var presentationMode
    @State private var inputHost = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Endereço do PC Windows")) {
                    TextField("IP do PC (ex: 10.1.1.X)", text: $inputHost)
                        .keyboardType(.numbersAndPunctuation)
                }
                Section(footer: Text("O micro-servidor no PC deve estar rodando na porta \(pcService.port).")) {
                    Button("Salvar e Reconectar") {
                        pcService.host = inputHost.trimmingCharacters(in: .whitespaces)
                        Task { await pcService.fetchTelemetry() }
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Configurações do PC")
            .onAppear {
                inputHost = pcService.host
            }
        }
    }
}
