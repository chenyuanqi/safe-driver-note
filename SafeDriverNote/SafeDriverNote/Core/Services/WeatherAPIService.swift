import Foundation
import CoreLocation

// MARK: - API响应数据模型
struct OpenWeatherResponse: Codable {
    let coord: Coordinates
    let weather: [WeatherInfo]
    let main: Main
    let visibility: Int
    let wind: Wind
    let clouds: Clouds
    let dt: Int
    let sys: Sys
    let timezone: Int
    let id: Int
    let name: String
    let cod: Int
}

struct Coordinates: Codable {
    let lon: Double
    let lat: Double
}

struct WeatherInfo: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct Main: Codable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let pressure: Int
    let humidity: Int
    let seaLevel: Int?
    let grndLevel: Int?

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure
        case humidity
        case seaLevel = "sea_level"
        case grndLevel = "grnd_level"
    }
}

struct Wind: Codable {
    let speed: Double
    let deg: Int?
    let gust: Double?
}

struct Clouds: Codable {
    let all: Int
}

struct Sys: Codable {
    let type: Int?
    let id: Int?
    let country: String
    let sunrise: Int
    let sunset: Int
}

// MARK: - 5日天气预报数据模型
struct ForecastResponse: Codable {
    let cod: String
    let message: Int
    let cnt: Int
    let list: [ForecastItem]
    let city: City
}

struct ForecastItem: Codable {
    let dt: Int
    let main: Main
    let weather: [WeatherInfo]
    let clouds: Clouds
    let wind: Wind
    let visibility: Int
    let pop: Double // 降水概率
    let sys: ForecastSys
    let dtTxt: String

    enum CodingKeys: String, CodingKey {
        case dt, main, weather, clouds, wind, visibility, pop, sys
        case dtTxt = "dt_txt"
    }
}

struct ForecastSys: Codable {
    let pod: String // "d" for day, "n" for night
}

struct City: Codable {
    let id: Int
    let name: String
    let coord: Coordinates
    let country: String
    let population: Int?
    let timezone: Int
    let sunrise: Int
    let sunset: Int
}

// MARK: - API错误响应数据模型
struct WeatherAPIErrorResponse: Codable {
    let cod: Int
    let message: String
}

// MARK: - 天气API服务
class WeatherAPIService {
    static let shared = WeatherAPIService()

    private init() {}

    /// 检查API配置是否有效
    private func validateConfiguration() throws {
        guard WeatherConfig.isRealWeatherEnabled else {
            throw WeatherAPIError.apiKeyMissing
        }
    }

    // 获取当前天气
    func fetchCurrentWeather(for location: CLLocation, getLocationDescription: ((CLLocation) async -> String)? = nil) async throws -> WeatherData {
        try validateConfiguration()

        let urlString = "\(WeatherConfig.baseURL)/weather?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(WeatherConfig.apiKey)&units=\(WeatherConfig.temperatureUnit)&lang=\(WeatherConfig.language)"

        guard let url = URL(string: urlString) else {
            throw WeatherAPIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        // 检查HTTP状态码
        if let httpResponse = response as? HTTPURLResponse {
            // print("天气API状态码: \(httpResponse.statusCode)")

            if httpResponse.statusCode != 200 {
                if let _ = String(data: data, encoding: .utf8) {
                    // print("天气API错误响应: \(jsonString)")
                }

                // 尝试解码错误响应
                if let errorResponse = try? JSONDecoder().decode(WeatherAPIErrorResponse.self, from: data) {
                    throw WeatherAPIError.apiError(errorResponse.message)
                } else {
                    throw WeatherAPIError.networkError(NSError(domain: "WeatherAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API调用失败，状态码: \(httpResponse.statusCode)"]))
                }
            }
        }

        if let _ = String(data: data, encoding: .utf8) {
            // print("天气API响应: \(jsonString)")
        }

        let apiResponse = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)

        // 获取中文地址描述，如果没有提供函数则使用API返回的英文名称
        let cityName: String
        if let getLocationDescription = getLocationDescription {
            cityName = await getLocationDescription(location)
        } else {
            cityName = apiResponse.name
        }

        return WeatherData(
            city: cityName,
            temperature: Int(apiResponse.main.temp.rounded()),
            condition: mapWeatherCondition(apiResponse.weather.first?.main ?? "", description: apiResponse.weather.first?.description ?? ""),
            conditionIcon: apiResponse.weather.first?.icon ?? "",
            feelsLike: Int(apiResponse.main.feelsLike.rounded()),
            humidity: apiResponse.main.humidity,
            windSpeed: apiResponse.wind.speed * 3.6 // 转换为 km/h
        )
    }

    // 获取5日天气预报（包含3小时间隔数据）
    func fetchWeatherForecast(for location: CLLocation) async throws -> (daily: [DailyWeatherData], hourly: [HourlyWeatherData]) {
        try validateConfiguration()

        let urlString = "\(WeatherConfig.baseURL)/forecast?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(WeatherConfig.apiKey)&units=\(WeatherConfig.temperatureUnit)&lang=\(WeatherConfig.language)"

        guard let url = URL(string: urlString) else {
            throw WeatherAPIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        // 检查HTTP状态码
        if let httpResponse = response as? HTTPURLResponse {
            // print("预报API状态码: \(httpResponse.statusCode)")

            if httpResponse.statusCode != 200 {
                if let _ = String(data: data, encoding: .utf8) {
                    // print("预报API错误响应: \(jsonString)")
                }

                // 尝试解码错误响应
                if let errorResponse = try? JSONDecoder().decode(WeatherAPIErrorResponse.self, from: data) {
                    throw WeatherAPIError.apiError(errorResponse.message)
                } else {
                    throw WeatherAPIError.networkError(NSError(domain: "WeatherAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "预报API调用失败，状态码: \(httpResponse.statusCode)"]))
                }
            }
        }

        if let _ = String(data: data, encoding: .utf8) {
            // print("预报API响应: \(jsonString.prefix(500))...") // 只打印前500字符避免过长
        }

        let forecastResponse = try JSONDecoder().decode(ForecastResponse.self, from: data)

        let daily = processDailyForecast(forecastResponse.list)
        let hourly = processHourlyForecast(forecastResponse.list)

        return (daily: daily, hourly: hourly)
    }

    // 处理日预报数据
    private func processDailyForecast(_ items: [ForecastItem]) -> [DailyWeatherData] {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "M月d日"

        // 按日期分组
        let grouped = Dictionary(grouping: items) { item in
            let date = Date(timeIntervalSince1970: TimeInterval(item.dt))
            return Calendar.current.startOfDay(for: date)
        }

        var dailyData: [DailyWeatherData] = []
        let sortedDates = grouped.keys.sorted()

        for (index, date) in sortedDates.prefix(3).enumerated() {
            guard let dayItems = grouped[date] else { continue }

            let temperatures = dayItems.map { Int($0.main.temp.rounded()) }
            let highTemp = temperatures.max() ?? 0
            let lowTemp = temperatures.min() ?? 0

            // 选择白天的天气作为主要天气
            let dayItem = dayItems.first {
                let hour = Calendar.current.component(.hour, from: Date(timeIntervalSince1970: TimeInterval($0.dt)))
                return hour >= 12 && hour <= 18
            } ?? dayItems.first!

            let dateString = index == 0 ? "今天" : (index == 1 ? "明天" : "后天")
            let condition = mapWeatherCondition(dayItem.weather.first?.main ?? "", description: dayItem.weather.first?.description ?? "")

            dailyData.append(DailyWeatherData(
                date: dateString,
                fullDate: dateFormatter.string(from: date),
                condition: condition,
                conditionIcon: dayItem.weather.first?.icon ?? "",
                highTemperature: highTemp,
                lowTemperature: lowTemp,
                precipitationChance: Int((dayItem.pop * 100).rounded())
            ))
        }

        return dailyData
    }

    // 处理小时预报数据（取未来24小时）
    private func processHourlyForecast(_ items: [ForecastItem]) -> [HourlyWeatherData] {
        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "HH:00"

        return items.prefix(8).map { item in // 8个3小时间隔 = 24小时
            let date = Date(timeIntervalSince1970: TimeInterval(item.dt))
            let _ = Calendar.current.component(.hour, from: date)
            let condition = mapWeatherCondition(item.weather.first?.main ?? "", description: item.weather.first?.description ?? "", isNight: item.sys.pod == "n")

            return HourlyWeatherData(
                hour: hourFormatter.string(from: date),
                temperature: Int(item.main.temp.rounded()),
                condition: condition,
                conditionIcon: item.weather.first?.icon ?? "",
                precipitationChance: Int((item.pop * 100).rounded())
            )
        }
    }

    // 映射天气条件
    private func mapWeatherCondition(_ main: String, description: String, isNight: Bool = false) -> String {
        switch main.lowercased() {
        case "clear":
            return isNight ? "晴夜" : "晴"
        case "clouds":
            if description.contains("few") {
                return "多云"
            } else {
                return "阴"
            }
        case "rain":
            if description.contains("light") {
                return "小雨"
            } else if description.contains("heavy") {
                return "大雨"
            } else {
                return "中雨"
            }
        case "thunderstorm":
            return "雷雨"
        case "snow":
            return "雪"
        case "mist", "fog", "haze":
            return "雾"
        default:
            return isNight ? "晴夜" : "晴"
        }
    }
}

// MARK: - 错误类型
enum WeatherAPIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case apiKeyMissing
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .decodingError(let error):
            return "数据解析错误: \(error.localizedDescription)"
        case .apiKeyMissing:
            return "缺少API密钥"
        case .apiError(let message):
            return "API错误: \(message)"
        }
    }
}