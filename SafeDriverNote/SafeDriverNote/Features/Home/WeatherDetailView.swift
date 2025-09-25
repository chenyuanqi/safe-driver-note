import SwiftUI

struct WeatherDetailView: View {
    @StateObject private var weatherService = WeatherService.shared
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // 当前天气信息
                    if let weather = weatherService.currentWeather {
                        currentWeatherSection(weather: weather)
                    }

                    // 24小时天气预报
                    hourlyWeatherSection()

                    // 3日天气预报
                    dailyWeatherSection()
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
            }
            .background(Color.pageBackground)
            .navigationTitle("天气详情")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.brandPrimary500)
                }
            }
        }
    }

    @ViewBuilder
    private func currentWeatherSection(weather: WeatherData) -> some View {
        Card(shadow: true) {
            VStack(spacing: Spacing.md) {
                // 城市和当前温度
                VStack(spacing: Spacing.xs) {
                    Text(weather.city)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)

                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: weather.systemIcon)
                            .font(.system(size: 40))
                            .foregroundColor(.brandPrimary500)

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("\(weather.temperature)°")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(.brandSecondary900)

                            Text(weather.shortDescription)
                                .font(.body)
                                .foregroundColor(.brandSecondary500)
                        }
                    }
                }

                Divider()
                    .background(Color.separatorColor)

                // 详细信息
                HStack(spacing: Spacing.xl) {
                    weatherDetailItem(
                        icon: "thermometer",
                        title: "体感温度",
                        value: "\(weather.feelsLike)°C"
                    )

                    weatherDetailItem(
                        icon: "humidity",
                        title: "湿度",
                        value: "\(weather.humidity)%"
                    )

                    weatherDetailItem(
                        icon: "wind",
                        title: "风速",
                        value: "\(Int(weather.windSpeed))km/h"
                    )
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
        }
    }

    @ViewBuilder
    private func weatherDetailItem(icon: String, title: String, value: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.brandInfo500)

            Text(title)
                .font(.bodySmall)
                .foregroundColor(.brandSecondary500)

            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.brandSecondary900)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func hourlyWeatherSection() -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("24小时天气预报")
                .font(.headline)
                .foregroundColor(.brandSecondary900)
                .padding(.horizontal, Spacing.sm)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(weatherService.hourlyWeather.prefix(24)) { hourWeather in
                        hourlyWeatherCard(hourWeather: hourWeather)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
    }

    @ViewBuilder
    private func hourlyWeatherCard(hourWeather: HourlyWeatherData) -> some View {
        Card(backgroundColor: .cardBackground, shadow: true) {
            VStack(spacing: Spacing.sm) {
                Text(hourWeather.hour)
                    .font(.bodySmall)
                    .foregroundColor(.brandSecondary500)
                    .frame(width: 60)
                    .multilineTextAlignment(.center)

                Image(systemName: hourWeather.systemIcon)
                    .font(.title3)
                    .foregroundColor(.brandPrimary500)
                    .frame(height: 20)

                Text("\(hourWeather.temperature)°")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.brandSecondary900)

                if hourWeather.precipitationChance > 30 {
                    HStack(spacing: 2) {
                        Image(systemName: "drop")
                            .font(.system(size: 8))
                            .foregroundColor(.brandInfo500)

                        Text("\(hourWeather.precipitationChance)%")
                            .font(.system(size: 10))
                            .foregroundColor(.brandInfo500)
                    }
                } else {
                    Spacer()
                        .frame(height: 12)
                }
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.md)
        }
        .frame(width: 80)
    }

    @ViewBuilder
    private func dailyWeatherSection() -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("3日天气预报")
                .font(.headline)
                .foregroundColor(.brandSecondary900)
                .padding(.horizontal, Spacing.sm)

            VStack(spacing: Spacing.sm) {
                ForEach(weatherService.dailyWeather) { dailyWeather in
                    dailyWeatherRow(dailyWeather: dailyWeather)
                }
            }
        }
    }

    @ViewBuilder
    private func dailyWeatherRow(dailyWeather: DailyWeatherData) -> some View {
        Card(backgroundColor: .cardBackground, shadow: true) {
            HStack(spacing: Spacing.md) {
                // 日期信息
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(dailyWeather.date)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)

                    Text(dailyWeather.fullDate)
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary500)
                }
                .frame(width: 60, alignment: .leading)

                // 天气图标和描述
                HStack(spacing: Spacing.sm) {
                    Image(systemName: dailyWeather.systemIcon)
                        .font(.title3)
                        .foregroundColor(.brandPrimary500)
                        .frame(width: 24)

                    Text(dailyWeather.condition)
                        .font(.body)
                        .foregroundColor(.brandSecondary700)
                }
                .frame(width: 80, alignment: .leading)

                Spacer()

                // 降水概率
                if dailyWeather.precipitationChance > 30 {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "drop")
                            .font(.caption)
                            .foregroundColor(.brandInfo500)

                        Text("\(dailyWeather.precipitationChance)%")
                            .font(.bodySmall)
                            .foregroundColor(.brandInfo500)
                    }
                    .frame(width: 50)
                } else {
                    Spacer()
                        .frame(width: 50)
                }

                // 温度范围
                HStack(spacing: Spacing.xs) {
                    Text("\(dailyWeather.highTemperature)°")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)

                    Text("/")
                        .font(.body)
                        .foregroundColor(.brandSecondary400)

                    Text("\(dailyWeather.lowTemperature)°")
                        .font(.body)
                        .foregroundColor(.brandSecondary500)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
    }
}

#if DEBUG
struct WeatherDetailView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherDetailView()
    }
}
#endif