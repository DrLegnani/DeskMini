import Foundation
import Combine

struct TelemetryData: Codable {
    let cpu_percent: Double
    let ram_used_gb: Double
    let ram_total_gb: Double
    let ram_percent: Double
    let uptime: String
    let agent_status: String // "idle", "working", "waiting_approval"
    let agent_message: String
    let pending_request: String?
}

@MainActor
class PCTelemetryService: ObservableObject {
    @Published var host: String = UserDefaults.standard.string(forKey: "pc_host") ?? "10.1.1.100" {
        didSet {
            UserDefaults.standard.set(host, forKey: "pc_host")
        }
    }
    
    @Published var port: Int = 8765
    @Published var isConnected: Bool = false
    @Published var cpuUsage: Double = 0.0
    @Published var ramUsedGB: Double = 0.0
    @Published var ramTotalGB: Double = 0.0
    @Published var ramPercent: Double = 0.0
    @Published var uptime: String = "--"
    @Published var agentStatus: String = "idle"
    @Published var agentMessage: String = "Pronto para receber comandos."
    @Published var pendingApproval: String? = nil
    @Published var isSending: Bool = false
    
    private var timer: AnyCancellable?
    
    init() {
        startPolling()
    }
    
    func startPolling() {
        timer?.cancel()
        timer = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.fetchTelemetry()
                }
            }
    }
    
    var baseURL: String {
        "http://\(host):\(port)"
    }
    
    func fetchTelemetry() async {
        guard let url = URL(string: "\(baseURL)/api/status") else { return }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 1.5
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let decoded = try JSONDecoder().decode(TelemetryData.self, from: data)
                self.isConnected = true
                self.cpuUsage = decoded.cpu_percent
                self.ramUsedGB = decoded.ram_used_gb
                self.ramTotalGB = decoded.ram_total_gb
                self.ramPercent = decoded.ram_percent
                self.uptime = decoded.uptime
                self.agentStatus = decoded.agent_status
                self.agentMessage = decoded.agent_message
                self.pendingApproval = decoded.pending_request
            } else {
                self.isConnected = false
            }
        } catch {
            self.isConnected = false
        }
    }
    
    func sendPrompt(_ text: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/prompt") else { return false }
        isSending = true
        defer { isSending = false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["prompt": text]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    func respondApproval(approved: Bool) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/approval") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["approved": approved]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if (response as? HTTPURLResponse)?.statusCode == 200 {
                self.pendingApproval = nil
                return true
            }
            return false
        } catch {
            return false
        }
    }
    
    func triggerMediaAction(_ action: String) async {
        guard let url = URL(string: "\(baseURL)/api/media") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["action": action]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: request)
    }
}
