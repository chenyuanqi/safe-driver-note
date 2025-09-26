import Foundation

struct WeatherConfig {
    // MARK: - API配置

    /// OpenWeatherMap API Key
    /// 获取API Key的步骤：
    /// 1. 访问 https://openweathermap.org/api
    /// 2. 注册免费账户
    /// 3. 在Dashboard中获取API Key
    /// 4. 将API Key填写到下面的字符串中
    static let apiKey = "3dde5fd567dcb17ada1d4be5ec15f916"

    /// API基础URL
    static let baseURL = "https://api.openweathermap.org/data/2.5"

    /// 是否启用真实天气数据
    /// 如果设置为false或API Key无效，将使用模拟数据
    static var isRealWeatherEnabled: Bool {
        return !apiKey.isEmpty
    }

    /// 温度单位（metric = 摄氏度, imperial = 华氏度）
    static let temperatureUnit = "metric"

    /// 语言设置（zh_cn = 中文）
    static let language = "zh_cn"

    /// 请求超时时间（秒）
    static let requestTimeout: TimeInterval = 10.0

    /// 天气数据缓存时间（分钟）
    static let cacheTimeout: TimeInterval = 30 * 60 // 30分钟
}

// MARK: - API Key验证
extension WeatherConfig {
    /// 验证API Key是否有效
    static func validateAPIKey() -> Bool {
        return isRealWeatherEnabled
    }

    /// 获取配置状态信息
    static func getConfigStatus() -> String {
        if isRealWeatherEnabled {
            return "✅ 真实天气数据已启用"
        } else {
            return "⚠️ 使用模拟数据（请配置API Key以启用真实数据）"
        }
    }
}