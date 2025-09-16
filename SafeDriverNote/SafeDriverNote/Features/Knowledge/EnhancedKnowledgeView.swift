import SwiftUI

struct EnhancedKnowledgeView: View {
    @StateObject private var vm = KnowledgeViewModel(repository: AppDI.shared.knowledgeRepository)
    @State private var selectedTab: KnowledgeTab = .daily
    @State private var showingQuiz = false
    @State private var showingAchievements = false
    @State private var searchText = ""
    @State private var selectedCategory: KnowledgeCategory = .all
    @State private var userLevel = UserLevel.beginner
    @State private var streakDays = 7
    @State private var totalPoints = 1250

    enum KnowledgeTab: String, CaseIterable {
        case daily = "每日学习"
        case library = "知识库"
        case practice = "实战练习"
        case community = "老司机说"

        var icon: String {
            switch self {
            case .daily: return "calendar.day.timeline.leading"
            case .library: return "books.vertical"
            case .practice: return "gamecontroller"
            case .community: return "person.3"
            }
        }
    }

    enum KnowledgeCategory: String, CaseIterable {
        case all = "全部"
        case traffic = "交通法规"
        case safety = "安全驾驶"
        case maintenance = "车辆保养"
        case emergency = "紧急处理"
        case experience = "经验技巧"

        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .traffic: return "signpost.right"
            case .safety: return "shield.checkered"
            case .maintenance: return "wrench.and.screwdriver"
            case .emergency: return "exclamationmark.triangle"
            case .experience: return "star"
            }
        }

        var color: Color {
            switch self {
            case .all: return .brandSecondary600
            case .traffic: return .brandInfo500
            case .safety: return .brandPrimary500
            case .maintenance: return .brandWarning500
            case .emergency: return .brandDanger500
            case .experience: return .brandPrimary600
            }
        }
    }

    enum UserLevel: String {
        case beginner = "新手司机"
        case intermediate = "熟练司机"
        case advanced = "老司机"
        case master = "驾驶大师"

        var icon: String {
            switch self {
            case .beginner: return "car"
            case .intermediate: return "car.fill"
            case .advanced: return "car.2"
            case .master: return "crown"
            }
        }

        var color: Color {
            switch self {
            case .beginner: return .brandSecondary500
            case .intermediate: return .brandInfo500
            case .advanced: return .brandPrimary500
            case .master: return .brandWarning500
            }
        }

        var minPoints: Int {
            switch self {
            case .beginner: return 0
            case .intermediate: return 500
            case .advanced: return 1500
            case .master: return 3000
            }
        }

        var maxPoints: Int {
            switch self {
            case .beginner: return 499
            case .intermediate: return 1499
            case .advanced: return 2999
            case .master: return 99999
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            // 用户状态栏
            userStatusBar

            // Tab 选择器
            tabSelector

            // 内容区域
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    switch selectedTab {
                    case .daily:
                        dailyLearningView
                    case .library:
                        knowledgeLibraryView
                    case .practice:
                        practiceView
                    case .community:
                        communityView
                    }
                }
                .padding(.horizontal, Spacing.pagePadding)
                .padding(.vertical, Spacing.lg)
            }
            .background(Color.brandSecondary50)
        }
        .sheet(isPresented: $showingQuiz) {
            DrivingQuizView(
                category: selectedCategory,
                onComplete: { score in
                    totalPoints += score
                    updateUserLevel()
                }
            )
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsView(totalPoints: totalPoints, level: userLevel)
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Text("驾驶知识")
                .font(.navTitle)
                .fontWeight(.bold)
                .foregroundColor(.brandSecondary900)

            Spacer()

            Button(action: { showingAchievements = true }) {
                Image(systemName: "trophy")
                    .font(.title3)
                    .foregroundColor(.brandWarning500)
            }
        }
        .padding(.horizontal, Spacing.pagePadding)
        .padding(.vertical, Spacing.md)
        .background(Color.white)
    }

    // MARK: - 用户状态栏
    private var userStatusBar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(gradient)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

            HStack(spacing: Spacing.xl) {
                // 用户等级
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Image(systemName: userLevel.icon)
                            .font(.body)
                            .foregroundColor(.white)
                        Text(userLevel.rawValue)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    Text("\(totalPoints) 积分")
                        .font(.bodyLarge)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    // 进度条
                    ProgressView(value: levelProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }

                Spacer()

                // 连续学习
                VStack(spacing: Spacing.xs) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("\(streakDays)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text("连续学习")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(Spacing.cardPadding)
        }
        .padding(.horizontal, Spacing.pagePadding)
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [userLevel.color, userLevel.color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var levelProgress: Double {
        let current = totalPoints - userLevel.minPoints
        let total = userLevel.maxPoints - userLevel.minPoints
        return Double(current) / Double(total)
    }

    // MARK: - Tab 选择器
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(KnowledgeTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: Spacing.xs) {
                            Image(systemName: tab.icon)
                                .font(.title3)
                            Text(tab.rawValue)
                                .font(.caption)
                        }
                        .frame(width: 80)
                        .padding(.vertical, Spacing.sm)
                        .foregroundColor(selectedTab == tab ? .white : .brandSecondary600)
                        .background(
                            selectedTab == tab ? Color.brandPrimary500 : Color.clear
                        )
                        .cornerRadius(CornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, Spacing.pagePadding)
            .padding(.vertical, Spacing.md)
        }
        .background(Color.white)
    }

    // MARK: - 每日学习视图
    private var dailyLearningView: some View {
        VStack(spacing: Spacing.xl) {
            // 今日任务卡片
            dailyMissionCard

            // 快速知识卡片（可滑动）
            quickKnowledgeCards

            // 今日测验
            dailyQuizCard
        }
    }

    private var dailyMissionCard: some View {
        Card(backgroundColor: Color.brandPrimary100, shadow: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundColor(.brandPrimary600)

                    Text("今日任务")
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandSecondary900)

                    Spacer()

                    Text("2/3 完成")
                        .font(.caption)
                        .foregroundColor(.brandSecondary600)
                }

                VStack(spacing: Spacing.sm) {
                    missionItem(title: "学习3个知识点", completed: true)
                    missionItem(title: "完成每日测验", completed: true)
                    missionItem(title: "分享一条经验", completed: false)
                }
            }
        }
    }

    private func missionItem(title: String, completed: Bool) -> some View {
        HStack {
            Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                .font(.body)
                .foregroundColor(completed ? .brandPrimary500 : .brandSecondary400)

            Text(title)
                .font(.body)
                .foregroundColor(completed ? .brandSecondary600 : .brandSecondary900)
                .strikethrough(completed)

            Spacer()

            if completed {
                Text("+10")
                    .font(.caption)
                    .foregroundColor(.brandPrimary500)
            }
        }
    }

    private var quickKnowledgeCards: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("快速学习")
                .font(.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(quickKnowledgeItems, id: \.title) { item in
                        quickKnowledgeCard(item)
                    }
                }
            }
        }
    }

    private func quickKnowledgeCard(_ item: QuickKnowledge) -> some View {
        Card(backgroundColor: item.color.opacity(0.1), shadow: false) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: item.icon)
                        .font(.title2)
                        .foregroundColor(item.color)

                    Spacer()

                    if item.isNew {
                        Text("NEW")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 2)
                            .background(Color.brandDanger500)
                            .cornerRadius(CornerRadius.xs)
                    }
                }

                Text(item.title)
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)
                    .lineLimit(2)

                Text(item.summary)
                    .font(.body)
                    .foregroundColor(.brandSecondary600)
                    .lineLimit(3)

                HStack {
                    Label("\(item.readTime)分钟", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.brandSecondary500)

                    Spacer()

                    Text("+\(item.points)分")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(item.color)
                }
            }
        }
        .frame(width: 250)
    }

    private var dailyQuizCard: some View {
        Card(backgroundColor: Color.brandInfo100.opacity(0.5), shadow: true) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                            .foregroundColor(.brandInfo500)

                        Text("每日测验")
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandSecondary900)
                    }

                    Text("测试今日所学，赢取积分")
                        .font(.body)
                        .foregroundColor(.brandSecondary600)

                    Button(action: { showingQuiz = true }) {
                        Text("开始测验")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.brandInfo500)
                            .cornerRadius(CornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Spacer()

                // 奖励预览
                VStack {
                    Text("🏆")
                        .font(.system(size: 40))
                    Text("+50分")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.brandWarning500)
                }
            }
        }
    }

    // MARK: - 知识库视图
    private var knowledgeLibraryView: some View {
        VStack(spacing: Spacing.xl) {
            // 搜索和筛选
            searchAndFilterBar

            // 分类网格
            categoryGrid

            // 热门知识列表
            popularKnowledgeList
        }
    }

    private var searchAndFilterBar: some View {
        HStack(spacing: Spacing.md) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.brandSecondary400)

                TextField("搜索驾驶知识", text: $searchText)
                    .font(.body)
            }
            .padding(Spacing.md)
            .background(Color.white)
            .cornerRadius(CornerRadius.md)

            Menu {
                ForEach(KnowledgeCategory.allCases, id: \.self) { category in
                    Button(action: { selectedCategory = category }) {
                        Label(category.rawValue, systemImage: category.icon)
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title3)
                    .foregroundColor(.brandSecondary600)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .cornerRadius(CornerRadius.md)
            }
        }
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
            ForEach(KnowledgeCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                categoryCard(category)
            }
        }
    }

    private func categoryCard(_ category: KnowledgeCategory) -> some View {
        Button(action: { selectedCategory = category }) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(category.color)

                Text(category.rawValue)
                    .font(.caption)
                    .foregroundColor(.brandSecondary700)

                Text("128篇")
                    .font(.caption2)
                    .foregroundColor(.brandSecondary500)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                selectedCategory == category ? category.color.opacity(0.1) : Color.white
            )
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(selectedCategory == category ? category.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var popularKnowledgeList: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("热门知识")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)

                Spacer()

                Button("查看全部") {
                    // 查看全部
                }
                .font(.body)
                .foregroundColor(.brandPrimary500)
            }

            VStack(spacing: Spacing.md) {
                ForEach(popularKnowledgeItems, id: \.title) { item in
                    knowledgeListItem(item)
                }
            }
        }
    }

    private func knowledgeListItem(_ item: KnowledgeItem) -> some View {
        Card(shadow: false) {
            HStack(spacing: Spacing.md) {
                // 图标
                Image(systemName: item.category.icon)
                    .font(.title2)
                    .foregroundColor(item.category.color)
                    .frame(width: 40, height: 40)
                    .background(item.category.color.opacity(0.1))
                    .cornerRadius(CornerRadius.sm)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(item.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)

                    HStack(spacing: Spacing.md) {
                        Label("\(item.viewCount)", systemImage: "eye")
                        Label("\(item.likeCount)", systemImage: "heart")
                        Label("\(item.difficulty)", systemImage: "star")
                    }
                    .font(.caption)
                    .foregroundColor(.brandSecondary500)
                }

                Spacer()

                if item.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.brandPrimary500)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.brandSecondary400)
                }
            }
        }
    }

    // MARK: - 实战练习视图
    private var practiceView: some View {
        VStack(spacing: Spacing.xl) {
            // 练习模式选择
            practiceModeSection

            // 排行榜
            leaderboardSection
        }
    }

    private var practiceModeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("选择练习模式")
                .font(.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)

            VStack(spacing: Spacing.md) {
                practiceCard(
                    title: "场景模拟",
                    description: "模拟真实驾驶场景，做出正确判断",
                    icon: "car.side",
                    color: .brandInfo500,
                    difficulty: "中等"
                )

                practiceCard(
                    title: "快速问答",
                    description: "限时回答，测试反应速度",
                    icon: "timer",
                    color: .brandWarning500,
                    difficulty: "简单"
                )

                practiceCard(
                    title: "案例分析",
                    description: "分析事故案例，学习经验教训",
                    icon: "doc.text.magnifyingglass",
                    color: .brandDanger500,
                    difficulty: "困难"
                )
            }
        }
    }

    private func practiceCard(title: String, description: String, icon: String, color: Color, difficulty: String) -> some View {
        Card(shadow: true) {
            HStack {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.1))
                    .cornerRadius(CornerRadius.md)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandSecondary900)

                    Text(description)
                        .font(.body)
                        .foregroundColor(.brandSecondary600)

                    HStack {
                        Text(difficulty)
                            .font(.caption)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 2)
                            .background(color.opacity(0.2))
                            .foregroundColor(color)
                            .cornerRadius(CornerRadius.xs)

                        Spacer()

                        Text("开始")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(color)
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - 社区视图
    private var communityView: some View {
        VStack(spacing: Spacing.xl) {
            // 老司机分享
            experienceSharingSection

            // 问答区
            qaSection
        }
    }

    private var experienceSharingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("老司机经验")
                .font(.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(experienceItems, id: \.author) { item in
                        experienceCard(item)
                    }
                }
            }
        }
    }

    private func experienceCard(_ item: ExperienceItem) -> some View {
        Card(shadow: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.brandSecondary400)

                    VStack(alignment: .leading) {
                        Text(item.author)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.brandSecondary900)

                        Text("\(item.drivingYears)年驾龄")
                            .font(.caption)
                            .foregroundColor(.brandSecondary500)
                    }

                    Spacer()
                }

                Text(item.title)
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)
                    .lineLimit(2)

                Text(item.content)
                    .font(.body)
                    .foregroundColor(.brandSecondary600)
                    .lineLimit(3)

                HStack {
                    Label("\(item.likes)", systemImage: "hand.thumbsup")
                        .font(.caption)
                        .foregroundColor(.brandSecondary500)

                    Spacer()

                    Text("阅读全文")
                        .font(.caption)
                        .foregroundColor(.brandPrimary500)
                }
            }
        }
        .frame(width: 280)
    }

    // MARK: - Helper Methods
    private func updateUserLevel() {
        if totalPoints >= UserLevel.master.minPoints {
            userLevel = .master
        } else if totalPoints >= UserLevel.advanced.minPoints {
            userLevel = .advanced
        } else if totalPoints >= UserLevel.intermediate.minPoints {
            userLevel = .intermediate
        } else {
            userLevel = .beginner
        }
    }

    // MARK: - Sample Data
    private let quickKnowledgeItems = [
        QuickKnowledge(
            title: "雨天行车安全距离",
            summary: "雨天路面湿滑，刹车距离会增加50%以上...",
            icon: "cloud.rain",
            color: .brandInfo500,
            readTime: 3,
            points: 15,
            isNew: true
        ),
        QuickKnowledge(
            title: "高速爆胎处理",
            summary: "切忌急刹车！握紧方向盘，缓慢减速...",
            icon: "exclamationmark.triangle",
            color: .brandDanger500,
            readTime: 5,
            points: 25,
            isNew: false
        ),
        QuickKnowledge(
            title: "省油驾驶技巧",
            summary: "保持经济时速，避免急加速急刹车...",
            icon: "fuelpump",
            color: .brandPrimary500,
            readTime: 4,
            points: 20,
            isNew: false
        )
    ]

    private let popularKnowledgeItems = [
        KnowledgeItem(
            title: "新手上高速必知的10个要点",
            category: .safety,
            viewCount: 2341,
            likeCount: 186,
            difficulty: "初级",
            isCompleted: true
        ),
        KnowledgeItem(
            title: "自动挡车的正确使用方法",
            category: .experience,
            viewCount: 1893,
            likeCount: 142,
            difficulty: "初级",
            isCompleted: false
        ),
        KnowledgeItem(
            title: "事故快速处理流程",
            category: .emergency,
            viewCount: 1567,
            likeCount: 201,
            difficulty: "中级",
            isCompleted: false
        )
    ]

    private let experienceItems = [
        ExperienceItem(
            author: "老王",
            drivingYears: 15,
            title: "夜间行车如何判断距离",
            content: "通过看对方车灯的高度变化，可以准确判断车距...",
            likes: 326
        ),
        ExperienceItem(
            author: "李师傅",
            drivingYears: 20,
            title: "长途驾驶防疲劳技巧",
            content: "每2小时休息15分钟，下车活动是关键...",
            likes: 289
        )
    ]

    private var leaderboardSection: some View {
        Card(shadow: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "chart.bar")
                        .font(.title3)
                        .foregroundColor(.brandWarning500)

                    Text("本周排行榜")
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandSecondary900)

                    Spacer()

                    Text("查看全部")
                        .font(.body)
                        .foregroundColor(.brandPrimary500)
                }

                VStack(spacing: Spacing.sm) {
                    leaderboardItem(rank: 1, name: "驾驶达人", points: 580, isCurrentUser: false)
                    leaderboardItem(rank: 2, name: "安全第一", points: 455, isCurrentUser: false)
                    leaderboardItem(rank: 3, name: "我", points: 420, isCurrentUser: true)
                }
            }
        }
    }

    private func leaderboardItem(rank: Int, name: String, points: Int, isCurrentUser: Bool) -> some View {
        HStack {
            // 排名
            ZStack {
                Circle()
                    .fill(rankColor(rank))
                    .frame(width: 30, height: 30)

                Text("\(rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Text(name)
                .font(.body)
                .fontWeight(isCurrentUser ? .semibold : .regular)
                .foregroundColor(isCurrentUser ? .brandPrimary500 : .brandSecondary900)

            Spacer()

            Text("\(points)分")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.brandSecondary700)
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, isCurrentUser ? Spacing.sm : 0)
        .background(isCurrentUser ? Color.brandPrimary100.opacity(0.5) : Color.clear)
        .cornerRadius(CornerRadius.sm)
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .brandWarning500
        case 2: return .brandSecondary400
        case 3: return .brandWarning600
        default: return .brandSecondary500
        }
    }

    private var qaSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("热门问答")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)

                Spacer()

                Button("提问") {
                    // 提问
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.brandPrimary500)
                .cornerRadius(CornerRadius.md)
            }

            VStack(spacing: Spacing.md) {
                qaItem(
                    question: "新车磨合期需要注意什么？",
                    answerCount: 12,
                    isAnswered: true
                )
                qaItem(
                    question: "自动挡下坡可以挂N档吗？",
                    answerCount: 8,
                    isAnswered: false
                )
            }
        }
    }

    private func qaItem(question: String, answerCount: Int, isAnswered: Bool) -> some View {
        Card(shadow: false) {
            HStack {
                Image(systemName: isAnswered ? "checkmark.seal.fill" : "questionmark.circle")
                    .font(.title3)
                    .foregroundColor(isAnswered ? .brandPrimary500 : .brandSecondary400)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(question)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)

                    Text("\(answerCount)个回答")
                        .font(.caption)
                        .foregroundColor(.brandSecondary500)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(.brandSecondary400)
            }
        }
    }
}

// MARK: - Data Models
struct QuickKnowledge {
    let title: String
    let summary: String
    let icon: String
    let color: Color
    let readTime: Int
    let points: Int
    let isNew: Bool
}

struct KnowledgeItem {
    let title: String
    let category: EnhancedKnowledgeView.KnowledgeCategory
    let viewCount: Int
    let likeCount: Int
    let difficulty: String
    let isCompleted: Bool
}

struct ExperienceItem {
    let author: String
    let drivingYears: Int
    let title: String
    let content: String
    let likes: Int
}