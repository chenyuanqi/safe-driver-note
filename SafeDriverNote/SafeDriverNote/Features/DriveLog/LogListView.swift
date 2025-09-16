import SwiftUI

struct LogListView: View {
    @StateObject private var vm = DriveLogViewModel(repository: AppDI.shared.logRepository)
    @State private var showingAdd = false
    @State private var searchText: String = ""
    @State private var selectedSegment: Segment = .all
    @State private var showingStats = false
    @State private var showingCalendar = false
    @State private var viewMode: ViewMode = .list

    enum ViewMode: String, CaseIterable {
        case list = "列表"
        case calendar = "日历"
        case timeline = "时间线"
    }

    // 组合项类型，用于"全部"tab
    struct CombinedItem {
        let id: String
        let date: Date
        let type: CombinedItemType

        enum CombinedItemType {
            case log(LogEntry)
            case route(DriveRoute)
        }
    }
    
    // 添加初始化参数，用于指定默认选中的tab
    var defaultTab: Segment?

    // 将枚举改为public，以便外部可以访问
    public enum Segment: String, CaseIterable {
        case all = "全部"
        case mistake = "失误"
        case success = "成功"
        case driveRoute = "行驶记录"
    }
    
    init(defaultTab: Segment? = nil) {
        self.defaultTab = defaultTab
    }

    var body: some View {
        VStack(spacing: 0) {
            StandardNavigationBar(
                title: "驾驶日志",
                showBackButton: false,
                trailingButtons: [
                    StandardNavigationBar.NavBarButton(icon: "plus") {
                        showingAdd = true
                    },
                    StandardNavigationBar.NavBarButton(icon: "chart.bar.xaxis") {
                        showingStats = true
                    }
                ]
            )
            
            ScrollView {
                VStack(spacing: Spacing.xxxl) {
                    // Tab Bar
                    tabBarSection

                    // View Mode Selector
                    viewModeSelectorSection

                    // Filter Bar
                    filterBarSection

                    // Content
                    Group {
                        if viewMode == .calendar {
                            CalendarView(logs: filteredLogs, routes: filteredRoutes)
                                .padding(.horizontal, Spacing.pagePadding)
                        } else if viewMode == .timeline {
                            timelineView
                        } else {
                            if selectedSegment == .driveRoute {
                            if filteredRoutes.isEmpty {
                                driveRouteEmptyStateView
                            } else {
                                driveRouteListView
                            }
                        } else if selectedSegment == .all {
                            if filteredLogs.isEmpty && filteredRoutes.isEmpty {
                                emptyStateView
                            } else {
                                combinedListView
                            }
                        } else {
                            if filteredLogs.isEmpty {
                                emptyStateView
                            } else {
                                logListView
                            }
                        }
                        }
                    }
                }
                .padding(.horizontal, Spacing.pagePadding)
                .padding(.vertical, Spacing.lg)
            }
            .refreshable {
                await refreshLogData()
            }
            .background(Color.brandSecondary50)
        }
        .sheet(isPresented: $showingAdd) {
            LogEditorView(entry: nil) { type, detail, location, scene, cause, improvement, tags, photos, audioFileName, transcript in
                vm.create(type: type,
                          detail: detail,
                          locationNote: location,
                          scene: scene,
                          cause: cause,
                          improvement: improvement,
                          rawTags: tags,
                          photoIds: photos,
                          audioFileName: audioFileName,
                          transcript: transcript)
            }
        }
        .sheet(item: $vm.editing) { entry in
            LogEditorView(entry: entry) { type, detail, location, scene, cause, improvement, tags, photos, audioFileName, transcript in
                vm.update(entry: entry,
                          type: type,
                          detail: detail,
                          locationNote: location,
                          scene: scene,
                          cause: cause,
                          improvement: improvement,
                          rawTags: tags,
                          photoIds: photos,
                          audioFileName: audioFileName,
                          transcript: transcript)
            }
        }
        .sheet(isPresented: $showingStats) {
            NavigationStack {
                LogStatsView(logs: vm.logs)
                    .navigationTitle("数据统计")
            }
        }
        .onAppear {
            // 如果有默认tab，则设置选中状态
            if let defaultTab = defaultTab {
                selectedSegment = defaultTab
                updateFilter(for: defaultTab)
            }
        }
    }
    
    // MARK: - View Mode Selector Section
    private var viewModeSelectorSection: some View {
        HStack(spacing: 0) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.spring()) {
                        viewMode = mode
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: iconForViewMode(mode))
                            .font(.body)
                        Text(mode.rawValue)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .foregroundColor(viewMode == mode ? .brandPrimary500 : .brandSecondary500)
                    .background(
                        viewMode == mode ? Color.brandPrimary100 : Color.clear
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.md)
        .padding(.horizontal, Spacing.pagePadding)
    }

    private func iconForViewMode(_ mode: ViewMode) -> String {
        switch mode {
        case .list:
            return "list.bullet"
        case .calendar:
            return "calendar"
        case .timeline:
            return "timeline.selection"
        }
    }

    // MARK: - Tab Bar Section
    private var tabBarSection: some View {
        BrandSegmentedControl(
            selection: $selectedSegment,
            options: Segment.allCases,
            displayText: { $0.rawValue }
        )
        .background(Color.cardBackground)
        .onChange(of: selectedSegment) { _, newValue in
            updateFilter(for: newValue)
        }
    }
    
    // MARK: - Filter Bar Section
    private var filterBarSection: some View {
        VStack(spacing: Spacing.lg) {
            // Search and Filter Row
            HStack(spacing: Spacing.lg) {
                SearchField(
                    text: $searchText,
                    placeholder: selectedSegment == .driveRoute ? "搜索起点/终点地址" : "搜索场景/地点/标签"
                )
                
                // 只在非行驶记录时显示排序菜单
                if selectedSegment != .driveRoute {
                    Menu {
                        Button("最新优先") { /* Handle sort */ }
                        Button("最早优先") { /* Handle sort */ }
                        Button("按类型排序") { /* Handle sort */ }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.bodyLarge)
                            .foregroundColor(.brandSecondary700)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                                    .fill(Color.brandSecondary100)
                            )
                    }
                }
            }
            
            // 只在非行驶记录时显示统计数据
            if selectedSegment != .driveRoute {
                // Statistics Row
                monthlyStatsRow
                
                // Tag Filter Row
                tagFilterRow
            }
        }
        .background(Color.cardBackground)
    }
    
    // MARK: - Monthly Stats Row
    private var monthlyStatsRow: some View {
        HStack(spacing: Spacing.lg) {
            StatusCard(
                title: "本月总次数",
                value: "\(monthTotal)",
                color: .brandInfo500
            )
            
            StatusCard(
                title: "本月失误",
                value: "\(monthMistakes)",
                color: .brandDanger500
            )
            
            StatusCard(
                title: "改进率",
                value: improvementRateFormatted,
                color: .brandPrimary500
            )
        }
    }
    
    // MARK: - Tag Filter Row
    private var tagFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(vm.tagOptions, id: \.self) { tag in
                    Button {
                        vm.toggleMultiTag(tag)
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: vm.selectedTags.contains(tag) ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                            Text(tag)
                                .font(.caption)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                                .fill(vm.selectedTags.contains(tag) ? Color.brandPrimary100 : Color.brandSecondary100)
                        )
                        .foregroundColor(vm.selectedTags.contains(tag) ? .brandPrimary600 : .brandSecondary600)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: { vm.toggleShowAllTags() }) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: vm.showAllTags ? "chevron.up" : "ellipsis.circle")
                            .font(.caption)
                        Text(vm.showAllTags ? "收起" : "更多(\(vm.fullTagCount))")
                            .font(.caption)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                            .fill(Color.brandSecondary100)
                    )
                    .foregroundColor(.brandSecondary700)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, Spacing.pagePadding)
        }
    }
    
    // MARK: - Content Views
    private var emptyStateView: some View {
        EmptyStateCard(
            icon: "car",
            title: "还没有驾驶记录",
            subtitle: "开始记录你的安全驾驶之旅",
            actionTitle: "开始记录"
        ) {
            showingAdd = true
        }
        .padding(Spacing.pagePadding)
    }
    
    private var driveRouteEmptyStateView: some View {
        EmptyStateCard(
            icon: "car.side",
            title: "还没有行驶记录",
            subtitle: "从首页开始你的驾驶之旅",
            actionTitle: "去首页"
        ) {
            // 这里可以添加跳转到首页的逻辑
        }
        .padding(Spacing.pagePadding)
    }
    
    private var logListView: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                ForEach(groupedByDay, id: \.key) { section in
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Date Header
                        Text(section.key)
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandSecondary900)
                            .padding(.horizontal, Spacing.pagePadding)
                        
                        // Log Cards
                        VStack(spacing: Spacing.md) {
                            ForEach(section.items, id: \.id) { log in
                                modernLogCard(for: log)
                                    .padding(.horizontal, Spacing.pagePadding)
                                    .onTapGesture {
                                        vm.beginEdit(log)
                                    }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.lg)
        }
    }
    
    private var driveRouteListView: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                ForEach(groupedRoutesByDay, id: \.key) { section in
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Date Header
                        Text(section.key)
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandSecondary900)
                            .padding(.horizontal, Spacing.pagePadding)

                        // Route Cards
                        VStack(spacing: Spacing.md) {
                            ForEach(section.items, id: \.id) { route in
                                driveRouteCard(for: route)
                                    .padding(.horizontal, Spacing.pagePadding)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.lg)
        }
    }

    // MARK: - Timeline View
    private var timelineView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(combinedGroupedByDay, id: \.key) { section in
                    VStack(alignment: .leading, spacing: 0) {
                        // 日期头部
                        HStack {
                            Text(section.key)
                                .font(.bodyLarge)
                                .fontWeight(.semibold)
                                .foregroundColor(.brandSecondary900)
                            Spacer()
                            // 当日统计
                            HStack(spacing: Spacing.md) {
                                let logs = section.items.compactMap { item in
                                    if case .log(let log) = item.type { return log }
                                    return nil
                                }
                                let routes = section.items.compactMap { item in
                                    if case .route(let route) = item.type { return route }
                                    return nil
                                }
                                if !logs.isEmpty {
                                    Label("\(logs.count)", systemImage: "doc.text")
                                        .font(.caption)
                                        .foregroundColor(.brandSecondary500)
                                }
                                if !routes.isEmpty {
                                    Label("\(routes.count)", systemImage: "car")
                                        .font(.caption)
                                        .foregroundColor(.brandSecondary500)
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.pagePadding)
                        .padding(.vertical, Spacing.md)
                        .background(Color.brandSecondary100)

                        // 时间线项目
                        ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                            HStack(alignment: .top, spacing: Spacing.md) {
                                // 时间线轴
                                VStack(spacing: 0) {
                                    Circle()
                                        .fill(colorForItem(item))
                                        .frame(width: 12, height: 12)
                                    if index < section.items.count - 1 {
                                        Rectangle()
                                            .fill(Color.brandSecondary200)
                                            .frame(width: 2)
                                    }
                                }
                                .frame(width: 12)

                                // 内容
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text(timeForItem(item))
                                        .font(.caption)
                                        .foregroundColor(.brandSecondary500)

                                    switch item.type {
                                    case .log(let log):
                                        timelineLogCard(for: log)
                                    case .route(let route):
                                        timelineRouteCard(for: route)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Spacer()
                            }
                            .padding(.horizontal, Spacing.pagePadding)
                            .padding(.vertical, Spacing.sm)
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.lg)
        }
    }

    private func timelineLogCard(for log: LogEntry) -> some View {
        Card(backgroundColor: Color.cardBackground, shadow: false) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: log.type == .mistake ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(log.type == .mistake ? .brandDanger500 : .brandPrimary500)
                    Text(log.type == .mistake ? "失误" : "成功")
                        .font(.caption)
                        .foregroundColor(log.type == .mistake ? .brandDanger600 : .brandPrimary600)
                }

                Text(cleanTitle(for: log))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.brandSecondary900)
                    .lineLimit(2)

                if !log.tags.isEmpty {
                    Text(log.tags.prefix(3).map { "#\($0)" }.joined(separator: " "))
                        .font(.caption)
                        .foregroundColor(.brandSecondary500)
                }
            }
        }
        .onTapGesture {
            vm.beginEdit(log)
        }
    }

    private func timelineRouteCard(for route: DriveRoute) -> some View {
        NavigationLink(destination: DriveRouteDetailView(route: route).environmentObject(AppDI.shared)) {
            Card(backgroundColor: Color.cardBackground, shadow: false) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "car.fill")
                            .font(.caption)
                            .foregroundColor(.brandInfo500)
                        Text("行驶记录")
                            .font(.caption)
                            .foregroundColor(.brandInfo500)
                    }

                    Text(routeTitle(for: route))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)
                        .lineLimit(2)

                    if let duration = route.duration, let distance = route.distance {
                        Text("\(formatDuration(duration)) · \(formatDistance(distance))")
                            .font(.caption)
                            .foregroundColor(.brandSecondary500)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func colorForItem(_ item: CombinedItem) -> Color {
        switch item.type {
        case .log(let log):
            return log.type == .mistake ? .brandDanger500 : .brandPrimary500
        case .route:
            return .brandInfo500
        }
    }

    private func timeForItem(_ item: CombinedItem) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: item.date)
    }

    private var combinedListView: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                ForEach(combinedGroupedByDay, id: \.key) { section in
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Date Header
                        Text(section.key)
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandSecondary900)
                            .padding(.horizontal, Spacing.pagePadding)

                        // Combined Cards
                        VStack(spacing: Spacing.md) {
                            ForEach(section.items, id: \.id) { item in
                                switch item.type {
                                case .log(let log):
                                    modernLogCard(for: log)
                                        .padding(.horizontal, Spacing.pagePadding)
                                        .onTapGesture {
                                            vm.beginEdit(log)
                                        }
                                case .route(let route):
                                    driveRouteCard(for: route)
                                        .padding(.horizontal, Spacing.pagePadding)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.lg)
        }
    }
    
    // MARK: - Helper Methods
    private func updateFilter(for segment: Segment) {
        switch segment {
        case .all:
            vm.filter = nil
            // "全部"现在同时显示日志和行驶记录，但使用自定义的combinedListView
            vm.showDriveRoutes = false
        case .mistake:
            vm.filter = .mistake
            vm.showDriveRoutes = false
        case .success:
            vm.filter = .success
            vm.showDriveRoutes = false
        case .driveRoute:
            vm.filter = nil
            vm.showDriveRoutes = true
        }
    }
    
    private func modernLogCard(for log: LogEntry) -> some View {
        Card(shadow: true) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Header Row
                HStack {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: log.type == .mistake ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .font(.body)
                            .foregroundColor(log.type == .mistake ? .brandDanger500 : .brandPrimary500)
                        
                        Text(Self.zhCNFormatter.string(from: log.createdAt))
                            .font(.bodySmall)
                            .foregroundColor(.brandSecondary500)
                    }
                    
                    Spacer()
                    
                    Text(log.type == .mistake ? "失误" : "成功")
                        .tagStyle(log.type == .mistake ? .error : .success)
                    
                    // Swipe Actions Menu
                    Menu {
                        Button(role: .destructive) {
                            if let idx = vm.logs.firstIndex(where: { $0.id == log.id }) {
                                vm.delete(at: IndexSet(integer: idx))
                            }
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.body)
                            .foregroundColor(.brandSecondary500)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                                    .fill(Color.clear)
                            )
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(cleanTitle(for: log))
                        .font(.bodyLarge)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)
                        .multilineTextAlignment(.leading)
                    
                    if !log.locationNote.isEmpty || !log.scene.isEmpty {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "location")
                                .font(.bodySmall)
                                .foregroundColor(.brandSecondary500)
                            
                            Text("\(log.locationNote)  ·  \(log.scene)")
                                .font(.bodySmall)
                                .foregroundColor(.brandSecondary500)
                        }
                    }
                    
                    // Attachments
                    if let attach = vm.attachmentSummary(for: log) {
                        Text(attach)
                            .font(.caption)
                            .foregroundColor(.brandSecondary500)
                    }
                    
                    // Tags
                    if !log.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.sm) {
                                ForEach(log.tags.prefix(6), id: \.self) { tag in
                                    Text("#" + tag)
                                        .tagStyle(.neutral)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func cleanTitle(for log: LogEntry) -> String {
        if !log.scene.isEmpty { return log.scene }
        if !log.locationNote.isEmpty { return log.locationNote }
        if !log.detail.isEmpty { return String(log.detail.prefix(50)) }
        return "记录"
    }
    
    private func driveRouteCard(for route: DriveRoute) -> some View {
        NavigationLink(destination: DriveRouteDetailView(route: route).environmentObject(AppDI.shared)) {
            Card(shadow: true) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Header Row
                    HStack {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "car.fill")
                                .font(.body)
                                .foregroundColor(.brandPrimary500)
                            
                            Text(Self.zhCNFormatter.string(from: route.startTime))
                                .font(.bodySmall)
                                .foregroundColor(.brandSecondary500)
                        }
                        
                        Spacer()
                        
                        Text(route.status.displayName)
                            .tagStyle(statusTagType(for: route))
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(routeTitle(for: route))
                            .font(.bodyLarge)
                            .fontWeight(.medium)
                            .foregroundColor(.brandSecondary900)
                            .multilineTextAlignment(.leading)
                        
                        // 行驶信息
                        HStack(spacing: Spacing.xl) {
                            if let duration = route.duration {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "clock")
                                        .font(.bodySmall)
                                        .foregroundColor(.brandSecondary500)
                                    
                                    Text(formatDuration(duration))
                                        .font(.bodySmall)
                                        .foregroundColor(.brandSecondary700)
                                }
                            }
                            
                            if let distance = route.distance {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "road.lanes")
                                        .font(.bodySmall)
                                        .foregroundColor(.brandSecondary500)
                                    
                                    Text(formatDistance(distance))
                                        .font(.bodySmall)
                                        .foregroundColor(.brandSecondary700)
                                }
                            }
                        }
                        
                        // 位置信息
                        if route.startLocation != nil || route.endLocation != nil {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                if let startAddr = route.startLocation?.address {
                                    HStack(spacing: Spacing.sm) {
                                        Image(systemName: "location.circle")
                                            .font(.bodySmall)
                                            .foregroundColor(.brandPrimary500)
                                        Text("出发: \(startAddr)")
                                            .font(.bodySmall)
                                            .foregroundColor(.brandSecondary700)
                                    }
                                }
                                
                                if let endAddr = route.endLocation?.address {
                                    HStack(spacing: Spacing.sm) {
                                        Image(systemName: "location.circle.fill")
                                            .font(.bodySmall)
                                            .foregroundColor(.brandDanger500)
                                        Text("到达: \(endAddr)")
                                            .font(.bodySmall)
                                            .foregroundColor(.brandSecondary700)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func routeTitle(for route: DriveRoute) -> String {
        if let start = route.startLocation?.address, let end = route.endLocation?.address {
            return "\(start) → \(end)"
        } else if let start = route.startLocation?.address {
            return "从 \(start) 出发"
        } else if let end = route.endLocation?.address {
            return "抵达 \(end)"
        } else {
            return "行驶记录"
        }
    }
    
    private func statusTagType(for route: DriveRoute) -> TagStyle.TagType {
        switch route.status {
        case .active:
            return .warning
        case .completed:
            return .success
        case .cancelled:
            return .error
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1f公里", distance / 1000)
        } else {
            return String(format: "%.0f米", distance)
        }
    }

    private var filteredLogs: [LogEntry] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return vm.logs }
        return vm.logs.filter { e in
            let hay = [e.detail, e.locationNote, e.scene, e.tags.joined(separator: " ")]
                .joined(separator: " ")
                .lowercased()
            return hay.contains(q)
        }
    }
    
    private var filteredRoutes: [DriveRoute] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // 对于"全部"tab，直接从allRoutes获取数据，否则使用vm.routes
        let sourcRoutes = (selectedSegment == .all) ? vm.allRoutes : vm.routes

        if q.isEmpty { return sourcRoutes }
        return sourcRoutes.filter { route in
            let startAddr = route.startLocation?.address ?? ""
            let endAddr = route.endLocation?.address ?? ""
            let hay = [startAddr, endAddr].joined(separator: " ").lowercased()
            return hay.contains(q)
        }
    }

    private var groupedByDay: [(key: String, items: [LogEntry])] {
        let df = DateFormatter()
        df.locale = Locale(identifier: "zh_CN")
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "yyyy年M月d日 EEEE"
        let groups = Dictionary(grouping: filteredLogs) { e in df.string(from: e.createdAt) }
        return groups
            .map { ($0.key, $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { lhs, rhs in lhs.items.first?.createdAt ?? .distantPast > rhs.items.first?.createdAt ?? .distantPast }
    }
    
    private var groupedRoutesByDay: [(key: String, items: [DriveRoute])] {
        let df = DateFormatter()
        df.locale = Locale(identifier: "zh_CN")
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "yyyy年M月d日 EEEE"
        let groups = Dictionary(grouping: filteredRoutes) { route in df.string(from: route.startTime) }
        return groups
            .map { ($0.key, $0.value.sorted { $0.startTime > $1.startTime }) }
            .sorted { lhs, rhs in lhs.items.first?.startTime ?? .distantPast > rhs.items.first?.startTime ?? .distantPast }
    }

    private var combinedGroupedByDay: [(key: String, items: [CombinedItem])] {
        let df = DateFormatter()
        df.locale = Locale(identifier: "zh_CN")
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "yyyy年M月d日 EEEE"

        // 将日志和行驶记录合并为CombinedItem
        var combinedItems: [CombinedItem] = []

        // 添加日志
        for log in filteredLogs {
            combinedItems.append(CombinedItem(
                id: "log_\(log.id)",
                date: log.createdAt,
                type: .log(log)
            ))
        }

        // 添加行驶记录
        for route in filteredRoutes {
            combinedItems.append(CombinedItem(
                id: "route_\(route.id)",
                date: route.startTime,
                type: .route(route)
            ))
        }

        // 按日期分组
        let groups = Dictionary(grouping: combinedItems) { item in df.string(from: item.date) }
        return groups
            .map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
            .sorted { lhs, rhs in lhs.items.first?.date ?? .distantPast > rhs.items.first?.date ?? .distantPast }
    }

    private var list: some View {
        List {
            ForEach(groupedByDay, id: \.key) { section in
                Section(section.key) {
                    ForEach(section.items, id: \.id) { log in
                        logCard(for: log)
                            .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if let idx = vm.logs.firstIndex(where: { $0.id == log.id }) {
                                        vm.delete(at: IndexSet(integer: idx))
                                    }
                                } label: { Label("删除", systemImage: "trash") }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { vm.beginEdit(log) }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "car")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("还没有驾驶记录")
                .font(.headline)
            Text("开始记录你的安全驾驶之旅")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                showingAdd = true
            } label: {
                Label("开始记录", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }.padding()
    }

    private func prefixIcon(for type: LogType) -> String { type == .mistake ? "⚠️ " : "✅ " }

    private func title(for log: LogEntry) -> String {
        let icon = prefixIcon(for: log.type)
        if !log.scene.isEmpty { return icon + log.scene }
        if !log.locationNote.isEmpty { return icon + log.locationNote }
        if !log.detail.isEmpty { return icon + String(log.detail.prefix(18)) }
        return icon + "记录"
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Search row: TextField + filter menu
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("搜索场景/地点/标签", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            // Stats summary
            HStack(spacing: 12) {
                statCard(title: "本月总次数", value: "\(monthTotal)", color: .brandInfo500)
                statCard(title: "本月失误", value: "\(monthMistakes)", color: .brandDanger500)
                statCard(title: "改进率", value: improvementRateFormatted, color: .brandPrimary500)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.tagOptions, id: \.self) { tag in
                        Button {
                            vm.toggleMultiTag(tag)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: vm.selectedTags.contains(tag) ? "checkmark.circle.fill" : "circle")
                                Text(tag)
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.brandSecondary100)
                            .clipShape(Capsule())
                        }
                    }
                    Button(action: { vm.toggleShowAllTags() }) {
                        Label(vm.showAllTags ? "收起" : "更多(\(vm.fullTagCount))", systemImage: vm.showAllTags ? "chevron.up" : "ellipsis.circle")
                    }
                    .font(.caption)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func logCard(for log: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(Self.zhCNFormatter.string(from: log.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(log.type == .mistake ? "失误" : "成功")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background((log.type == .mistake ? Color.brandDanger100 : Color.brandPrimary100))
                    .foregroundColor(log.type == .mistake ? .brandDanger600 : .brandPrimary700)
                    .clipShape(Capsule())
            }
            Text(title(for: log))
                .font(.body)
            if !log.locationNote.isEmpty || !log.scene.isEmpty {
                Text("📍 \(log.locationNote)  ·  \(log.scene)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                if let attach = vm.attachmentSummary(for: log) {
                    Text(attach)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            if !log.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(log.tags.prefix(6), id: \.self) { tag in
                        Text("#" + tag)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.brandPrimary50)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(12)
        .background(Color.brandSecondary100)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Month Stats
    private var monthLogs: [LogEntry] {
        let cal = Calendar(identifier: .gregorian)
        guard let start = cal.date(from: cal.dateComponents([.year, .month], from: Date())) else { return [] }
        return vm.logs.filter { $0.createdAt >= start }
    }

    private var monthRoutes: [DriveRoute] {
        let cal = Calendar(identifier: .gregorian)
        guard let start = cal.date(from: cal.dateComponents([.year, .month], from: Date())) else { return [] }
        // 对于"全部"tab，使用allRoutes；否则使用routes
        let sourceRoutes = (selectedSegment == .all) ? vm.allRoutes : vm.routes
        return sourceRoutes.filter { $0.startTime >= start }
    }

    private var monthTotal: Int {
        // 在"全部"模式下，总次数 = 日志数 + 行驶记录数
        if selectedSegment == .all {
            return monthLogs.count + monthRoutes.count
        } else {
            return monthLogs.count
        }
    }

    private var monthMistakes: Int { monthLogs.filter { $0.type == .mistake }.count }
    private var monthSuccess: Int { monthLogs.filter { $0.type == .success }.count }
    private var improvementRateFormatted: String {
        // 改进率只基于日志数据计算（成功/总日志数），不包含行驶记录
        let totalLogs = monthLogs.count
        guard totalLogs > 0 else { return "--%" }
        let rate = Double(monthSuccess) / Double(totalLogs)
        return String(format: "%.0f%%", rate * 100)
    }
    @ViewBuilder
    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Date Formatter (Chinese)
    private static let zhCNFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy年M月d日 HH:mm" // 示例：2025年8月18日 16:37
        return f
    }()

    // MARK: - Pull to Refresh
    private func refreshLogData() async {
        // 重新加载日志数据
        vm.load()

        // 添加轻微延迟以提供更好的用户体验
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
    }
}

#Preview { LogListView() }