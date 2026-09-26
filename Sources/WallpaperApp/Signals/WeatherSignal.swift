import Foundation

enum WeatherMood: String {
    case clear
    case cloudy
    case fog
    case drizzle
    case rain
    case snow
    case thunderstorm

    /// Maps Open-Meteo's WMO weather codes to a small set of visual moods.
    /// https://open-meteo.com/en/docs (WMO Weather interpretation codes)
    static func from(wmoCode: Int) -> WeatherMood {
        switch wmoCode {
        case 0, 1: return .clear
        case 2, 3: return .cloudy
        case 45, 48: return .fog
        case 51, 53, 55, 56, 57: return .drizzle
        case 61, 63, 65, 66, 67, 80, 81, 82: return .rain
        case 71, 73, 75, 77, 85, 86: return .snow
        case 95, 96, 99: return .thunderstorm
        default: return .clear
        }
    }
}

struct WeatherContext {
    let mood: WeatherMood
    let temperatureC: Double

    private struct Response: Decodable {
        struct Current: Decodable {
            let temperature_2m: Double
            let weather_code: Int
        }
        let current: Current
    }

    /// Fetches current conditions from Open-Meteo (no API key required).
    /// Returns nil if location isn't configured or the request fails —
    /// callers should fall back to a time/battery-only wallpaper.
    static func fetch(latitude: Double, longitude: Double) async -> WeatherContext? {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            return WeatherContext(
                mood: WeatherMood.from(wmoCode: decoded.current.weather_code),
                temperatureC: decoded.current.temperature_2m
            )
        } catch {
            return nil
        }
    }
}
