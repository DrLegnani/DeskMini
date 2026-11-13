import Foundation

struct WeatherData: Codable {
    let current: CurrentWeather?
    let hourly: HourlyWeather?
}

struct CurrentWeather: Codable {
    let time: String
    let temperature_2m: Double
    let relative_humidity_2m: Int
    let apparent_temperature: Double
    let is_day: Int
    let weather_code: Int
}

struct HourlyWeather: Codable {
    let time: [String]
    let temperature_2m: [Double]
    let weather_code: [Int]
}

@MainActor
class WeatherService: ObservableObject {
    @Published var temperature: Double = 0.0
    @Published var apparentTemp: Double = 0.0
    @Published var humidity: Int = 0
    @Published var conditionText: String = "Carregando..."
    @Published var conditionIcon: String = "cloud.sun.fill"
    @Published var hourlyForecast: [(hour: String, temp: Double, icon: String)] = []
    @Published var isLoading: Bool = false
    
    // Coordenadas padrão (São Paulo - alterável nas configurações)
    var latitude: Double = -23.5505
    var longitude: Double = -46.6333
    
    func fetchWeather() async {
        isLoading = true
        defer { isLoading = false }
        
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code&hourly=temperature_2m,weather_code&timezone=auto&forecast_days=1"
        
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(WeatherData.self, from: data)
            
            if let current = decoded.current {
                self.temperature = current.temperature_2m
                self.apparentTemp = current.apparent_temperature
                self.humidity = current.relative_humidity_2m
                let (text, icon) = weatherCodeToInfo(code: current.weather_code, isDay: current.is_day == 1)
                self.conditionText = text
                self.conditionIcon = icon
            }
            
            if let hourly = decoded.hourly {
                var forecast: [(hour: String, temp: Double, icon: String)] = []
                let count = min(hourly.time.count, hourly.temperature_2m.count)
                let calendar = Calendar.current
                let currentHour = calendar.component(.hour, from: Date())
                
                for i in 0..<count {
                    let timeStr = hourly.time[i] // formato "2026-11-13T15:00"
                    if let hourPart = timeStr.split(separator: "T").last?.prefix(2),
                       let hourInt = Int(hourPart), hourInt >= currentHour {
                        let (_, icon) = weatherCodeToInfo(code: hourly.weather_code[i], isDay: hourInt >= 6 && hourInt < 19)
                        forecast.append((hour: "\(hourPart)h", temp: hourly.temperature_2m[i], icon: icon))
                        if forecast.count >= 6 { break }
                    }
                }
                self.hourlyForecast = forecast
            }
        } catch {
            print("Erro ao buscar clima: \(error)")
            self.conditionText = "Indisponível"
            self.conditionIcon = "exclamationmark.triangle"
        }
    }
    
    private func weatherCodeToInfo(code: Int, isDay: Bool) -> (String, String) {
        switch code {
        case 0:
            return ("Céu limpo", isDay ? "sun.max.fill" : "moon.stars.fill")
        case 1, 2:
            return ("Parcialmente nublado", isDay ? "cloud.sun.fill" : "cloud.moon.fill")
        case 3:
            return ("Nublado", "cloud.fill")
        case 45, 48:
            return ("Nevoeiro", "cloud.fog.fill")
        case 51, 53, 55, 61, 63, 65:
            return ("Chuva", "cloud.rain.fill")
        case 80, 81, 82:
            return ("Pancadas de chuva", "cloud.heavyrain.fill")
        case 95, 96, 99:
            return ("Tempestade", "cloud.bolt.rain.fill")
        default:
            return ("Tempo bom", "cloud.sun.fill")
        }
    }
}
