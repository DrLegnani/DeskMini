import SwiftUI

@main
struct DeskMiniApp: App {
    init() {
        // Impede que a tela do iPad desligue automaticamente enquanto estiver no modo mesa
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
