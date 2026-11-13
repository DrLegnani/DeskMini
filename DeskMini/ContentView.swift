import SwiftUI

struct ContentView: View {
    @StateObject private var weatherService = WeatherService()
    @State private var currentTime = Date()
    @State private var isNightMode = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    private var secondsFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = ":ss"
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, d 'de' MMMM"
        return formatter
    }
    
    var body: some View {
        ZStack {
            // Fundo
            (isNightMode ? Color.black : Color(red: 0.08, green: 0.09, blue: 0.12))
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Barra Superior
                HStack {
                    Label("DeskMini", systemImage: "sparkles")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(accentColor.opacity(0.8))
                    
                    Spacer()
                    
                    // Botão Atualizar Clima
                    Button(action: {
                        Task { await weatherService.fetchWeather() }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .rotationEffect(.degrees(weatherService.isLoading ? 360 : 0))
                                .animation(weatherService.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: weatherService.isLoading)
                            Text("Atualizar")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(cardBackground)
                        .cornerRadius(20)
                        .foregroundColor(textColor)
                    }
                    
                    // Botão Modo Noturno
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isNightMode.toggle()
                        }
                    }) {
                        Image(systemName: isNightMode ? "moon.fill" : "sun.max.fill")
                            .font(.system(size: 16, weight: .medium))
                            .padding(8)
                            .background(cardBackground)
                            .clipShape(Circle())
                            .foregroundColor(isNightMode ? .red : .yellow)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)
                
                // Conteúdo Principal (2 Colunas em Paisagem)
                HStack(alignment: .top, spacing: 24) {
                    // Coluna da Esquerda: Relógio e Data
                    VStack(alignment: .leading, spacing: 16) {
                        Spacer()
                        
                        // Horas e Segundos
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(timeFormatter.string(from: currentTime))
                                .font(.system(size: 100, weight: .light, design: .rounded))
                                .foregroundColor(textColor)
                            
                            Text(secondsFormatter.string(from: currentTime))
                                .font(.system(size: 38, weight: .regular, design: .rounded))
                                .foregroundColor(accentColor.opacity(0.7))
                        }
                        
                        // Data por extenso
                        Text(dateFormatter.string(from: currentTime).capitalized)
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                            .foregroundColor(secondaryTextColor)
                        
                        Spacer()
                        
                        // Mini Calendário da Semana
                        WeekCalendarView(accentColor: accentColor, isNightMode: isNightMode)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(28)
                    .background(cardBackground)
                    .cornerRadius(24)
                    
                    // Coluna da Direita: Clima e Previsão
                    VStack(spacing: 20) {
                        // Card do Clima Atual
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("TEMPO ATUAL")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(secondaryTextColor)
                                Spacer()
                                Image(systemName: weatherService.conditionIcon)
                                    .font(.system(size: 32))
                                    .foregroundColor(isNightMode ? .red : .orange)
                            }
                            
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(String(format: "%.0f°", weatherService.temperature))
                                    .font(.system(size: 56, weight: .medium, design: .rounded))
                                    .foregroundColor(textColor)
                                
                                Text(weatherService.conditionText)
                                    .font(.system(size: 20, weight: .regular, design: .rounded))
                                    .foregroundColor(secondaryTextColor)
                            }
                            
                            HStack(spacing: 16) {
                                Label("Sensação \(String(format: "%.0f°", weatherService.apparentTemp))", systemImage: "thermometer")
                                Label("\(weatherService.humidity)% umidade", systemImage: "humidity.fill")
                            }
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(secondaryTextColor)
                        }
                        .padding(24)
                        .background(cardBackground)
                        .cornerRadius(24)
                        
                        // Previsão Horária
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PRÓXIMAS HORAS")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(secondaryTextColor)
                            
                            HStack(spacing: 12) {
                                ForEach(weatherService.hourlyForecast.indices, id: \.self) { index in
                                    let item = weatherService.hourlyForecast[index]
                                    VStack(spacing: 8) {
                                        Text(item.hour)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(secondaryTextColor)
                                        Image(systemName: item.icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(isNightMode ? .red : .orange)
                                        Text(String(format: "%.0f°", item.temp))
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(textColor)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(24)
                        .background(cardBackground)
                        .cornerRadius(24)
                        
                        // Card de Ações Rápidas
                        HStack(spacing: 12) {
                            QuickActionButton(title: isNightMode ? "Luz Normal" : "Luz Noturna",
                                              icon: isNightMode ? "sun.max" : "moon.stars",
                                              color: accentColor) {
                                withAnimation { isNightMode.toggle() }
                            }
                            
                            QuickActionButton(title: "Atualizar",
                                              icon: "arrow.clockwise",
                                              color: accentColor) {
                                Task { await weatherService.fetchWeather() }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
        .onReceive(timer) { input in
            currentTime = input
        }
        .task {
            await weatherService.fetchWeather()
        }
    }
    
    // Cores dinâmicas para alternância entre modo normal e noturno
    private var cardBackground: Color {
        if isNightMode {
            return Color(white: 0.08)
        } else {
            return Color(red: 0.14, green: 0.15, blue: 0.20)
        }
    }
    
    private var textColor: Color {
        isNightMode ? Color(red: 0.95, green: 0.25, blue: 0.20) : .white
    }
    
    private var secondaryTextColor: Color {
        isNightMode ? Color(red: 0.70, green: 0.20, blue: 0.15) : Color(white: 0.7)
    }
    
    private var accentColor: Color {
        isNightMode ? Color(red: 0.90, green: 0.20, blue: 0.15) : Color(red: 0.35, green: 0.65, blue: 1.0)
    }
}

// Widget da semana
struct WeekCalendarView: View {
    let accentColor: Color
    let isNightMode: Bool
    
    private let calendar = Calendar.current
    private let weekDays = ["D", "S", "T", "Q", "Q", "S", "S"]
    
    var body: some View {
        HStack(spacing: 10) {
            let currentDayOfWeek = calendar.component(.weekday, from: Date()) - 1
            ForEach(0..<7, id: \.self) { day in
                let isToday = day == currentDayOfWeek
                VStack(spacing: 6) {
                    Text(weekDays[day])
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isToday ? (isNightMode ? .red : .white) : Color(white: 0.5))
                    Circle()
                        .fill(isToday ? accentColor : Color.clear)
                        .frame(width: 6, height: 6)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isToday ? accentColor.opacity(0.15) : Color.clear)
                .cornerRadius(12)
            }
        }
    }
}

// Botão de ação rápida
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(white: 0.12))
            .foregroundColor(color)
            .cornerRadius(16)
        }
    }
}
