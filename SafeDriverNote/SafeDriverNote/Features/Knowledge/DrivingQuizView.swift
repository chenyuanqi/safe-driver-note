import SwiftUI

struct DrivingQuizView: View {
    let category: EnhancedKnowledgeView.KnowledgeCategory
    let onComplete: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentQuestion = 0
    @State private var selectedAnswer: Int? = nil
    @State private var showingResult = false
    @State private var correctAnswers = 0
    @State private var timeRemaining = 30
    @State private var timer: Timer?
    @State private var showingExplanation = false

    let questions = [
        QuizQuestion(
            question: "雨天行车时，刹车距离会比平时增加多少？",
            options: ["20%", "30%", "50%以上", "没有变化"],
            correctAnswer: 2,
            explanation: "雨天路面湿滑，轮胎与地面的摩擦力降低，刹车距离会增加50%以上，甚至更多。"
        ),
        QuizQuestion(
            question: "高速公路上最低车速是多少？",
            options: ["40km/h", "50km/h", "60km/h", "70km/h"],
            correctAnswer: 2,
            explanation: "根据交通法规，高速公路最低车速为60km/h，低于此速度会影响交通流畅。"
        ),
        QuizQuestion(
            question: "夜间会车时应该：",
            options: ["开远光灯", "关闭所有灯光", "切换为近光灯", "开雾灯"],
            correctAnswer: 2,
            explanation: "夜间会车时应切换为近光灯，避免远光灯对对方司机造成眩目。"
        ),
        QuizQuestion(
            question: "轮胎气压过低会导致：",
            options: ["油耗增加", "轮胎磨损加快", "行驶不稳", "以上都是"],
            correctAnswer: 3,
            explanation: "轮胎气压过低会增加滚动阻力导致油耗增加，同时加速轮胎磨损，影响行驶稳定性。"
        ),
        QuizQuestion(
            question: "发动机水温过高应该：",
            options: ["立即加水", "继续行驶到维修店", "停车等待降温", "加大油门快速行驶"],
            correctAnswer: 2,
            explanation: "水温过高应立即停车等待降温，切勿立即打开水箱盖，避免高温蒸汽烫伤。"
        )
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部进度条
                progressBar

                // 问题区域
                if currentQuestion < questions.count {
                    questionView
                } else {
                    resultView
                }
            }
            .background(Color.brandSecondary50)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("退出") {
                        timer?.invalidate()
                        dismiss()
                    }
                    .foregroundColor(.brandSecondary600)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Image(systemName: "timer")
                        Text("\(timeRemaining)s")
                    }
                    .font(.body)
                    .foregroundColor(timeRemaining < 10 ? .brandDanger500 : .brandSecondary600)
                }
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.brandSecondary200)

                Rectangle()
                    .fill(Color.brandPrimary500)
                    .frame(width: geometry.size.width * Double(currentQuestion) / Double(questions.count))
                    .animation(.spring(), value: currentQuestion)
            }
        }
        .frame(height: 4)
    }

    private var questionView: some View {
        let question = questions[currentQuestion]

        return VStack(spacing: Spacing.xl) {
            // 问题编号
            HStack {
                Text("问题 \(currentQuestion + 1)/\(questions.count)")
                    .font(.body)
                    .foregroundColor(.brandSecondary500)

                Spacer()

                Text("分值：10分")
                    .font(.body)
                    .foregroundColor(.brandWarning500)
            }
            .padding(.horizontal, Spacing.pagePadding)
            .padding(.top, Spacing.lg)

            // 问题
            Card(shadow: true) {
                Text(question.question)
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.pagePadding)

            // 选项
            VStack(spacing: Spacing.md) {
                ForEach(0..<question.options.count, id: \.self) { index in
                    answerOption(text: question.options[index], index: index)
                }
            }
            .padding(.horizontal, Spacing.pagePadding)

            // 解释（如果显示）
            if showingExplanation {
                Card(backgroundColor: Color.brandInfo100.opacity(0.5), shadow: false) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.brandInfo500)
                            Text("知识点")
                                .font(.bodyLarge)
                                .fontWeight(.semibold)
                                .foregroundColor(.brandSecondary900)
                        }

                        Text(question.explanation)
                            .font(.body)
                            .foregroundColor(.brandSecondary700)
                    }
                }
                .padding(.horizontal, Spacing.pagePadding)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer()

            // 操作按钮
            HStack(spacing: Spacing.md) {
                if currentQuestion > 0 {
                    Button(action: previousQuestion) {
                        Text("上一题")
                            .font(.body)
                            .foregroundColor(.brandSecondary600)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(Color.white)
                            .cornerRadius(CornerRadius.md)
                    }
                }

                Button(action: nextQuestion) {
                    Text(currentQuestion < questions.count - 1 ? "下一题" : "完成")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(
                            selectedAnswer != nil ? Color.brandPrimary500 : Color.brandSecondary300
                        )
                        .cornerRadius(CornerRadius.md)
                }
                .disabled(selectedAnswer == nil)
            }
            .padding(.horizontal, Spacing.pagePadding)
            .padding(.bottom, Spacing.lg)
        }
    }

    private func answerOption(text: String, index: Int) -> some View {
        let isSelected = selectedAnswer == index
        let isCorrect = showingExplanation && index == questions[currentQuestion].correctAnswer
        let isWrong = showingExplanation && isSelected && index != questions[currentQuestion].correctAnswer

        return Button(action: {
            if !showingExplanation {
                selectAnswer(index)
            }
        }) {
            HStack {
                Circle()
                    .fill(backgroundColor(isSelected: isSelected, isCorrect: isCorrect, isWrong: isWrong))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Group {
                            if isCorrect {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            } else if isWrong {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                    )

                Text(text)
                    .font(.body)
                    .foregroundColor(.brandSecondary900)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(optionBackground(isSelected: isSelected, isCorrect: isCorrect, isWrong: isWrong))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(borderColor(isSelected: isSelected, isCorrect: isCorrect, isWrong: isWrong), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(showingExplanation)
    }

    private func backgroundColor(isSelected: Bool, isCorrect: Bool, isWrong: Bool) -> Color {
        if isCorrect { return .brandPrimary500 }
        if isWrong { return .brandDanger500 }
        if isSelected { return .brandPrimary500 }
        return .white
    }

    private func optionBackground(isSelected: Bool, isCorrect: Bool, isWrong: Bool) -> Color {
        if isCorrect { return Color.brandPrimary100 }
        if isWrong { return Color.brandDanger100 }
        if isSelected { return Color.brandPrimary100 }
        return .white
    }

    private func borderColor(isSelected: Bool, isCorrect: Bool, isWrong: Bool) -> Color {
        if isCorrect { return .brandPrimary500 }
        if isWrong { return .brandDanger500 }
        if isSelected { return .brandPrimary500 }
        return .brandSecondary200
    }

    private var resultView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // 成绩展示
            ZStack {
                Circle()
                    .fill(scoreColor)
                    .frame(width: 150, height: 150)

                VStack {
                    Text("\(score)%")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)

                    Text(scoreText)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                }
            }

            // 统计信息
            VStack(spacing: Spacing.md) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.brandPrimary500)
                    Text("答对 \(correctAnswers) 题")
                        .font(.body)
                        .foregroundColor(.brandSecondary700)
                }

                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.brandDanger500)
                    Text("答错 \(questions.count - correctAnswers) 题")
                        .font(.body)
                        .foregroundColor(.brandSecondary700)
                }

                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.brandWarning500)
                    Text("获得 \(earnedPoints) 积分")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandSecondary900)
                }
            }
            .padding(Spacing.lg)
            .background(Color.white)
            .cornerRadius(CornerRadius.lg)
            .padding(.horizontal, Spacing.pagePadding)

            Spacer()

            // 操作按钮
            VStack(spacing: Spacing.md) {
                Button(action: {
                    onComplete(earnedPoints)
                    dismiss()
                }) {
                    Text("完成")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.brandPrimary500)
                        .cornerRadius(CornerRadius.md)
                }

                Button(action: restart) {
                    Text("再来一次")
                        .font(.body)
                        .foregroundColor(.brandPrimary500)
                }
            }
            .padding(.horizontal, Spacing.pagePadding)
            .padding(.bottom, Spacing.lg)
        }
    }

    private var score: Int {
        Int(Double(correctAnswers) / Double(questions.count) * 100)
    }

    private var scoreColor: Color {
        if score >= 80 { return .brandPrimary500 }
        if score >= 60 { return .brandWarning500 }
        return .brandDanger500
    }

    private var scoreText: String {
        if score >= 80 { return "优秀！" }
        if score >= 60 { return "良好" }
        return "继续努力"
    }

    private var earnedPoints: Int {
        correctAnswers * 10
    }

    // MARK: - Actions
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                if currentQuestion < questions.count - 1 {
                    nextQuestion()
                } else {
                    currentQuestion = questions.count
                }
            }
        }
    }

    private func selectAnswer(_ index: Int) {
        selectedAnswer = index

        // 自动显示解释
        withAnimation {
            showingExplanation = true
        }

        // 检查答案
        if index == questions[currentQuestion].correctAnswer {
            correctAnswers += 1
        }

        // 2秒后自动跳转下一题
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if currentQuestion < questions.count - 1 {
                nextQuestion()
            }
        }
    }

    private func nextQuestion() {
        if currentQuestion < questions.count - 1 {
            withAnimation {
                currentQuestion += 1
                selectedAnswer = nil
                showingExplanation = false
                timeRemaining = 30
            }
        } else {
            timer?.invalidate()
            withAnimation {
                currentQuestion = questions.count
            }
        }
    }

    private func previousQuestion() {
        if currentQuestion > 0 {
            withAnimation {
                currentQuestion -= 1
                selectedAnswer = nil
                showingExplanation = false
            }
        }
    }

    private func restart() {
        currentQuestion = 0
        selectedAnswer = nil
        showingExplanation = false
        correctAnswers = 0
        timeRemaining = 30
        startTimer()
    }
}

// MARK: - Quiz Question Model
struct QuizQuestion {
    let question: String
    let options: [String]
    let correctAnswer: Int
    let explanation: String
}

// MARK: - 成就系统视图
struct AchievementsView: View {
    let totalPoints: Int
    let level: EnhancedKnowledgeView.UserLevel

    @Environment(\.dismiss) private var dismiss

    let achievements = [
        Achievement(
            title: "初出茅庐",
            description: "完成首次学习",
            icon: "star",
            isUnlocked: true,
            progress: 1.0
        ),
        Achievement(
            title: "连续学习7天",
            description: "连续7天坚持学习",
            icon: "flame",
            isUnlocked: true,
            progress: 1.0
        ),
        Achievement(
            title: "知识达人",
            description: "学习100个知识点",
            icon: "book",
            isUnlocked: false,
            progress: 0.65
        ),
        Achievement(
            title: "测验高手",
            description: "测验正确率达到90%",
            icon: "checkmark.seal",
            isUnlocked: false,
            progress: 0.8
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // 用户信息卡片
                    userInfoCard

                    // 成就列表
                    achievementsList
                }
                .padding(.horizontal, Spacing.pagePadding)
                .padding(.vertical, Spacing.lg)
            }
            .background(Color.brandSecondary50)
            .navigationTitle("我的成就")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var userInfoCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(LinearGradient(
                    colors: [level.color, level.color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

            VStack(spacing: Spacing.lg) {
                // 等级图标
                Image(systemName: level.icon)
                    .font(.system(size: 60))
                    .foregroundColor(.white)

                Text(level.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("\(totalPoints) 总积分")
                    .font(.bodyLarge)
                    .foregroundColor(.white.opacity(0.9))

                // 下一等级进度
                if level != .master {
                    VStack(spacing: Spacing.xs) {
                        HStack {
                            Text("距离下一等级")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))

                            Spacer()

                            Text("\(nextLevelPoints - totalPoints)分")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }

                        ProgressView(value: levelProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                    }
                }
            }
            .padding(Spacing.cardPadding)
        }
    }

    private var nextLevelPoints: Int {
        switch level {
        case .beginner: return EnhancedKnowledgeView.UserLevel.intermediate.minPoints
        case .intermediate: return EnhancedKnowledgeView.UserLevel.advanced.minPoints
        case .advanced: return EnhancedKnowledgeView.UserLevel.master.minPoints
        case .master: return 99999
        }
    }

    private var levelProgress: Double {
        let current = totalPoints - level.minPoints
        let total = nextLevelPoints - level.minPoints
        return Double(current) / Double(total)
    }

    private var achievementsList: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("成就徽章")
                .font(.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                ForEach(achievements, id: \.title) { achievement in
                    achievementCard(achievement)
                }
            }
        }
    }

    private func achievementCard(_ achievement: Achievement) -> some View {
        Card(backgroundColor: achievement.isUnlocked ? Color.white : Color.brandSecondary100, shadow: false) {
            VStack(spacing: Spacing.md) {
                // 图标
                ZStack {
                    Circle()
                        .fill(achievement.isUnlocked ? Color.brandWarning500 : Color.brandSecondary300)
                        .frame(width: 60, height: 60)

                    Image(systemName: achievement.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .opacity(achievement.isUnlocked ? 1.0 : 0.5)

                // 标题
                Text(achievement.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(achievement.isUnlocked ? .brandSecondary900 : .brandSecondary500)

                // 描述
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.brandSecondary600)
                    .multilineTextAlignment(.center)

                // 进度条
                if !achievement.isUnlocked {
                    ProgressView(value: achievement.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .brandPrimary500))
                }
            }
        }
    }
}

// MARK: - Achievement Model
struct Achievement {
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
    let progress: Double
}