import Foundation
import CoreLocation
import Combine

// 小时天气数据模型
struct HourlyWeatherData: Codable, Identifiable {
    let id = UUID()
    let hour: String // "14:00"
    let temperature: Int
    let condition: String
    let conditionIcon: String
    let precipitationChance: Int // 降水概率

    var systemIcon: String {
        switch condition.lowercased() {
        case "晴天", "晴":
            return "sun.max"
        case "晴夜":
            return "moon.stars"
        case "多云":
            return "cloud"
        case "阴天", "阴":
            return "cloud.fill"
        case "雨天", "雨", "小雨", "中雨", "大雨":
            return "cloud.rain"
        case "雷雨", "雷电":
            return "cloud.bolt.rain"
        case "雪天", "雪":
            return "cloud.snow"
        case "雾天", "雾":
            return "cloud.fog"
        default:
            return "sun.max"
        }
    }
}

// 日天气数据模型
struct DailyWeatherData: Codable, Identifiable {
    let id = UUID()
    let date: String // "今天", "明天", "后天"
    let fullDate: String // "12月25日"
    let condition: String
    let conditionIcon: String
    let highTemperature: Int
    let lowTemperature: Int
    let precipitationChance: Int

    var systemIcon: String {
        switch condition.lowercased() {
        case "晴天", "晴":
            return "sun.max"
        case "多云":
            return "cloud"
        case "阴天", "阴":
            return "cloud.fill"
        case "雨天", "雨", "小雨", "中雨", "大雨":
            return "cloud.rain"
        case "雷雨", "雷电":
            return "cloud.bolt.rain"
        case "雪天", "雪":
            return "cloud.snow"
        case "雾天", "雾":
            return "cloud.fog"
        default:
            return "sun.max"
        }
    }
}

// 天气数据模型
struct WeatherData: Codable {
    let city: String
    let temperature: Int
    let condition: String
    let conditionIcon: String
    let feelsLike: Int
    let humidity: Int
    let windSpeed: Double
    
    // 根据天气条件返回相应的系统图标
    var systemIcon: String {
        switch condition.lowercased() {
        case "晴天", "晴":
            return "sun.max"
        case "多云":
            return "cloud"
        case "阴天", "阴":
            return "cloud.fill"
        case "雨天", "雨", "小雨", "中雨", "大雨":
            return "cloud.rain"
        case "雷雨", "雷电":
            return "cloud.bolt.rain"
        case "雪天", "雪":
            return "cloud.snow"
        case "雾天", "雾":
            return "cloud.fog"
        default:
            return "sun.max" // 默认晴天图标
        }
    }
    
    // 根据天气条件返回简短描述
    var shortDescription: String {
        switch condition.lowercased() {
        case "晴天", "晴":
            return "晴"
        case "多云":
            return "多云"
        case "阴天", "阴":
            return "阴"
        case "雨天", "雨", "小雨":
            return "小雨"
        case "中雨":
            return "中雨"
        case "大雨":
            return "大雨"
        case "雷雨", "雷电":
            return "雷雨"
        case "雪天", "雪":
            return "雪"
        case "雾天", "雾":
            return "雾"
        default:
            return condition
        }
    }
}

@MainActor
final class WeatherService: ObservableObject {
    static let shared = WeatherService()

    @Published private(set) var currentWeather: WeatherData?
    @Published private(set) var dailyWeather: [DailyWeatherData] = []
    @Published private(set) var hourlyWeather: [HourlyWeatherData] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private var weatherCancellable: AnyCancellable?

    private init() {}
    
    // 获取当前位置的天气信息
    func fetchCurrentWeather(
        hasLocationPermission: Bool,
        getCurrentLocation: (TimeInterval) async throws -> CLLocation?,
        getLocationDescription: (CLLocation) async -> String
    ) async {
        guard hasLocationPermission else {
            await MainActor.run {
                self.errorMessage = "需要位置权限才能获取天气信息"
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // 获取当前位置
            guard let location = try await getCurrentLocation(10.0) else {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "无法获取当前位置"
                }
                return
            }
            
            // 获取天气信息（模拟数据，实际项目中应调用真实天气API）
            let weather = await getMockWeatherData(for: location, getLocationDescription: getLocationDescription)
            let daily = await getMockDailyWeatherData()
            let hourly = await getMockHourlyWeatherData()

            await MainActor.run {
                self.currentWeather = weather
                self.dailyWeather = daily
                self.hourlyWeather = hourly
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "获取天气信息失败: \(error.localizedDescription)"
            }
        }
    }
    
    // 模拟天气数据（实际项目中应调用真实天气API）
    private func getMockWeatherData(for location: CLLocation, getLocationDescription: (CLLocation) async -> String) async -> WeatherData {
        // 获取城市名称
        let city = await getLocationDescription(location)
        
        // 生成模拟天气数据
        let conditions = ["晴", "多云", "阴", "小雨", "中雨", "大雨"]
        let condition = conditions[Int.random(in: 0..<conditions.count)]
        
        // 根据条件生成温度
        let temperature: Int
        switch condition {
        case "晴":
            temperature = Int.random(in: 25...35)
        case "多云", "阴":
            temperature = Int.random(in: 20...30)
        case "小雨":
            temperature = Int.random(in: 18...25)
        case "中雨":
            temperature = Int.random(in: 15...22)
        case "大雨":
            temperature = Int.random(in: 12...18)
        default:
            temperature = Int.random(in: 20...28)
        }
        
        let humidity = Int.random(in: 40...90)
        let windSpeed = Double.random(in: 0...20)
        let feelsLike = temperature + Int.random(in: -3...3)
        
        return WeatherData(
            city: city,
            temperature: temperature,
            condition: condition,
            conditionIcon: "", // 将在systemIcon计算属性中处理
            feelsLike: feelsLike,
            humidity: humidity,
            windSpeed: windSpeed
        )
    }
    
    // 生成模拟3日天气数据
    private func getMockDailyWeatherData() async -> [DailyWeatherData] {
        let conditions = ["晴", "多云", "阴", "小雨", "中雨"]
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "M月d日"

        var dailyData: [DailyWeatherData] = []

        for i in 0..<3 {
            let date = Calendar.current.date(byAdding: .day, value: i, to: Date()) ?? Date()
            let condition = conditions[Int.random(in: 0..<conditions.count)]

            var dateString: String
            switch i {
            case 0:
                dateString = "今天"
            case 1:
                dateString = "明天"
            case 2:
                dateString = "后天"
            default:
                dateString = "今天"
            }

            // 根据条件生成温度范围
            let (high, low): (Int, Int)
            switch condition {
            case "晴":
                high = Int.random(in: 28...35)
                low = Int.random(in: 18...25)
            case "多云":
                high = Int.random(in: 25...32)
                low = Int.random(in: 16...23)
            case "阴":
                high = Int.random(in: 22...28)
                low = Int.random(in: 14...20)
            case "小雨":
                high = Int.random(in: 20...25)
                low = Int.random(in: 12...18)
            case "中雨":
                high = Int.random(in: 18...23)
                low = Int.random(in: 10...16)
            default:
                high = Int.random(in: 20...28)
                low = Int.random(in: 15...22)
            }

            let precipitationChance = condition.contains("雨") ? Int.random(in: 60...90) : Int.random(in: 0...30)

            dailyData.append(DailyWeatherData(
                date: dateString,
                fullDate: dateFormatter.string(from: date),
                condition: condition,
                conditionIcon: "",
                highTemperature: high,
                lowTemperature: low,
                precipitationChance: precipitationChance
            ))
        }

        return dailyData
    }

    // 生成模拟小时天气数据
    private func getMockHourlyWeatherData() async -> [HourlyWeatherData] {
        let currentHour = Calendar.current.component(.hour, from: Date())
        var hourlyData: [HourlyWeatherData] = []

        for i in 0..<24 {
            let hour = (currentHour + i) % 24

            // 根据时间段选择合适的天气条件
            let condition: String
            let baseTemperature: Int

            if hour >= 6 && hour <= 18 { // 白天 (6:00-18:00)
                let dayConditions = ["晴", "多云", "阴", "小雨"]
                condition = dayConditions[Int.random(in: 0..<dayConditions.count)]

                switch condition {
                case "晴":
                    baseTemperature = Int.random(in: 25...32)
                case "多云":
                    baseTemperature = Int.random(in: 22...28)
                case "阴":
                    baseTemperature = Int.random(in: 20...25)
                case "小雨":
                    baseTemperature = Int.random(in: 18...23)
                default:
                    baseTemperature = Int.random(in: 20...26)
                }
            } else { // 夜晚 (19:00-5:00) - 避免使用"晴"，改为夜间适合的天气
                let nightConditions = ["多云", "阴", "小雨", "晴夜"] // 添加"晴夜"专门表示夜间晴朗
                condition = nightConditions[Int.random(in: 0..<nightConditions.count)]

                switch condition {
                case "晴夜":
                    baseTemperature = Int.random(in: 18...24)
                case "多云":
                    baseTemperature = Int.random(in: 16...22)
                case "阴":
                    baseTemperature = Int.random(in: 14...20)
                case "小雨":
                    baseTemperature = Int.random(in: 12...18)
                default:
                    baseTemperature = Int.random(in: 15...20)
                }
            }

            let precipitationChance = condition.contains("雨") ? Int.random(in: 50...80) : Int.random(in: 0...20)

            hourlyData.append(HourlyWeatherData(
                hour: String(format: "%02d:00", hour),
                temperature: baseTemperature,
                condition: condition,
                conditionIcon: "",
                precipitationChance: precipitationChance
            ))
        }

        return hourlyData
    }

    // 清除错误信息
    func clearError() {
        errorMessage = nil
    }
}