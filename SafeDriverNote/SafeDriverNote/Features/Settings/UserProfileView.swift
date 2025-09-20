import SwiftUI
import Foundation
import PhotosUI
import UniformTypeIdentifiers
import ImageIO
import UIKit

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var di: AppDI

    @State private var userName = "安全驾驶人"
    @State private var userAge = ""
    @State private var drivingYears = "3"
    @State private var vehicleType = "小型汽车"
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var avatarImage: Image?
    @State private var showingCropView = false
    @State private var userStats: UserStats?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingActionSheet = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    if isLoading {
                        // 加载状态
                        VStack(spacing: Spacing.lg) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("加载中...")
                                .font(.bodyMedium)
                                .foregroundColor(.brandSecondary500)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xxxl)
                    } else {
                        // 头像区域
                        profileImageSection

                        // 基本信息
                        basicInfoSection

                        // 驾驶信息
                        drivingInfoSection

                        // 成就统计
                        achievementSection
                    }
                }
                .padding(Spacing.pagePadding)
            }
            .background(Color.brandSecondary50)
            .navigationTitle("个人资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveUserProfile()
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving)
                }
            }
            .onAppear {
                loadUserProfile()
            }
            .alert("保存失败", isPresented: $showingError) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - 头像区域
    private var profileImageSection: some View {
        VStack(spacing: Spacing.md) {
            Button(action: {
                showingActionSheet = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.brandPrimary100)
                        .frame(width: 100, height: 100)

                    if let avatarImage = avatarImage {
                        avatarImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.brandPrimary500)
                    }

                    // 相机图标覆盖层
                    Circle()
                        .fill(Color.white)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.brandPrimary500)
                        )
                        .offset(x: 35, y: 35)
                }
                .overlay(
                    Circle()
                        .stroke(Color.cardBackground, lineWidth: 4)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }

            Text("点击更换头像")
                .font(.bodySmall)
                .foregroundColor(.brandSecondary500)
        }
        .confirmationDialog("选择头像来源", isPresented: $showingActionSheet, titleVisibility: .visible) {
            Button("从相册选择") {
                sourceType = .photoLibrary
                showingImagePicker = true
            }

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("拍照") {
                    sourceType = .camera
                    showingImagePicker = true
                }
            }

            if avatarImage != nil {
                Button("删除头像", role: .destructive) {
                    avatarImage = nil
                    selectedImage = nil
                }
            }

            Button("取消", role: .cancel) {}
        }
        .sheet(isPresented: $showingImagePicker) {
            if sourceType == .camera {
                CameraImagePicker(image: $selectedImage, showingCropView: $showingCropView)
            } else {
                ImagePicker(image: $selectedImage, showingCropView: $showingCropView)
            }
        }
        .sheet(isPresented: $showingCropView) {
            if let image = selectedImage {
                ImageCropView(
                    image: image,
                    croppedImage: $avatarImage,
                    isPresented: $showingCropView,
                    onComplete: { croppedUIImage in
                        selectedImage = croppedUIImage
                        avatarImage = Image(uiImage: croppedUIImage)
                    }
                )
            }
        }
    }

    // MARK: - 基本信息
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("基本信息")

            Card(shadow: true) {
                VStack(spacing: Spacing.lg) {
                    inputField(
                        title: "姓名",
                        value: $userName,
                        placeholder: "请输入您的姓名"
                    )

                    Divider()

                    inputField(
                        title: "年龄",
                        value: $userAge,
                        placeholder: "请输入您的年龄",
                        keyboardType: .numberPad
                    )
                }
                .padding(Spacing.lg)
            }
        }
    }

    // MARK: - 驾驶信息
    private var drivingInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("驾驶信息")

            Card(shadow: true) {
                VStack(spacing: Spacing.lg) {
                    inputField(
                        title: "驾龄",
                        value: $drivingYears,
                        placeholder: "请输入您的驾龄（年）",
                        keyboardType: .numberPad
                    )

                    Divider()

                    HStack {
                        Text("车辆类型")
                            .font(.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.brandSecondary900)

                        Spacer()

                        Picker("车辆类型", selection: $vehicleType) {
                            Text("小型汽车").tag("小型汽车")
                            Text("SUV").tag("SUV")
                            Text("货车").tag("货车")
                            Text("摩托车").tag("摩托车")
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                .padding(Spacing.lg)
            }
        }
    }

    // MARK: - 成就统计
    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("成就统计")

            Card(shadow: true) {
                VStack(spacing: Spacing.md) {
                    if let stats = userStats {
                        HStack {
                            achievementItem(
                                title: "安全评分",
                                value: "\(stats.safetyScore)",
                                unit: "分",
                                color: .brandPrimary500
                            )

                            achievementItem(
                                title: "连续天数",
                                value: "\(stats.currentStreakDays)",
                                unit: "天",
                                color: .brandInfo500
                            )

                            achievementItem(
                                title: "总里程",
                                value: formatDistance(stats.totalRouteDistance),
                                unit: stats.totalRouteDistance >= 1000 ? "km" : "m",
                                color: .brandWarning500
                            )
                        }

                        Divider()

                        if let achievement = stats.recentAchievement {
                            HStack {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("最近成就")
                                        .font(.bodyMedium)
                                        .fontWeight(.medium)
                                        .foregroundColor(.brandSecondary900)

                                    Text(achievement.description)
                                        .font(.bodySmall)
                                        .foregroundColor(.brandSecondary600)
                                }

                                Spacer()

                                Text(formatRelativeDate(achievement.achievedDate))
                                    .font(.caption)
                                    .foregroundColor(.brandSecondary400)
                            }
                        } else {
                            HStack {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("最近成就")
                                        .font(.bodyMedium)
                                        .fontWeight(.medium)
                                        .foregroundColor(.brandSecondary900)

                                    Text("继续努力，即将获得新成就！")
                                        .font(.bodySmall)
                                        .foregroundColor(.brandSecondary500)
                                }

                                Spacer()
                            }
                        }
                    } else {
                        // 加载状态
                        VStack(spacing: Spacing.md) {
                            ProgressView()
                            Text("加载统计数据...")
                                .font(.bodySmall)
                                .foregroundColor(.brandSecondary500)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                    }
                }
                .padding(Spacing.lg)
            }
        }
    }

    // MARK: - 辅助方法
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(.brandSecondary900)
            .padding(.leading, Spacing.sm)
    }

    private func inputField(
        title: String,
        value: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        HStack {
            Text(title)
                .font(.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(.brandSecondary900)
                .frame(width: 60, alignment: .leading)

            TextField(placeholder, text: value)
                .keyboardType(keyboardType)
                .textFieldStyle(PlainTextFieldStyle())
        }
    }

    private func achievementItem(
        title: String,
        value: String,
        unit: String,
        color: Color
    ) -> some View {
        VStack(spacing: Spacing.xs) {
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                Text(unit)
                    .font(.caption)
                    .foregroundColor(.brandSecondary500)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.brandSecondary500)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Data Loading & Saving

    private func loadUserProfile() {
        Task {
            do {
                let profile = try di.userProfileRepository.fetchUserProfile()
                let stats = try di.userProfileRepository.calculateUserStats()

                await MainActor.run {
                    self.userName = profile.userName
                    self.userAge = profile.userAge != nil ? "\(profile.userAge!)" : ""
                    self.drivingYears = "\(profile.drivingYears)"
                    self.vehicleType = profile.vehicleType
                    self.userStats = stats
                    self.loadAvatarImage(from: profile.avatarImagePath)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "加载用户资料失败：\(error.localizedDescription)"
                    self.showingError = true
                    self.isLoading = false
                }
            }
        }
    }

    private func saveUserProfile() {
        guard !isSaving else { return }

        isSaving = true

        Task {
            do {
                let ageValue = userAge.isEmpty ? nil : Int(userAge)
                let drivingYearsValue = Int(drivingYears) ?? 0

                // 保存头像图片
                var avatarPath: String? = nil
                if let uiImage = selectedImage {
                    avatarPath = saveAvatarImage(uiImage)
                }

                let updatedProfile = try di.userProfileRepository.updateUserProfile(
                    userName: userName,
                    userAge: ageValue,
                    drivingYears: drivingYearsValue,
                    vehicleType: vehicleType,
                    avatarImagePath: avatarPath
                )

                await MainActor.run {
                    self.isSaving = false
                    self.dismiss()
                }
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    self.errorMessage = "保存用户资料失败：\(error.localizedDescription)"
                    self.showingError = true
                }
            }
        }
    }

    // MARK: - Formatting Helpers

    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1f", distance / 1000)
        } else {
            return String(format: "%.0f", distance)
        }
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.day], from: date, to: now)

        if let days = components.day {
            if days == 0 {
                return "今天"
            } else if days == 1 {
                return "昨天"
            } else if days < 7 {
                return "\(days)天前"
            } else {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "zh_CN")
                formatter.dateFormat = "M月d日"
                return formatter.string(from: date)
            }
        }
        return ""
    }

    private func saveAvatarImage(_ image: UIImage) -> String? {
        // 压缩图片到合适大小
        let maxSize: CGFloat = 400
        let scale = min(maxSize / image.size.width, maxSize / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()

        guard let data = resizedImage.jpegData(compressionQuality: 0.7) else { return nil }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "avatar_\(UUID().uuidString).jpg"
        let fileURL = documentsPath.appendingPathComponent(fileName)

        do {
            // 删除旧的头像文件
            let oldFiles = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
                .filter { $0.lastPathComponent.hasPrefix("avatar_") && $0.pathExtension == "jpg" }
            for oldFile in oldFiles {
                try? FileManager.default.removeItem(at: oldFile)
            }

            try data.write(to: fileURL)
            return fileName
        } catch {
            print("Failed to save avatar image: \(error)")
            return nil
        }
    }

    private func loadAvatarImage(from path: String?) {
        guard let path = path else { return }

        Task {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsPath.appendingPathComponent(path)

            if let data = try? Data(contentsOf: fileURL),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    self.selectedImage = uiImage
                    self.avatarImage = Image(uiImage: uiImage)
                }
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var showingCropView: Bool
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current // 使用当前表示模式以提高性能

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            guard let provider = results.first?.itemProvider else { return }

            let identifier = UTType.image.identifier
            if provider.hasItemConformingToTypeIdentifier(identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: identifier) { data, error in
                    if let error = error {
                        print("Error loading image data: \(error)")
                        return
                    }

                    guard let data = data else { return }

                    let maxDimension: CGFloat = 1200
                    let processedImage = downsampleImage(data: data, maxDimension: maxDimension)

                    DispatchQueue.main.async {
                        if let image = processedImage {
                            let finalImage = resizeImageIfNeeded(image, maxDimension: maxDimension)
                            self.parent.image = finalImage
                            self.parent.showingCropView = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Camera Image Picker
struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var showingCropView: Bool
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker

        init(_ parent: CameraImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                imageProcessingQueue.async {
                    let maxDimension: CGFloat = 1200
                    let processedImage: UIImage
                    if let data = image.jpegData(compressionQuality: 0.9), let downsampled = downsampleImage(data: data, maxDimension: maxDimension) {
                        processedImage = downsampled
                    } else {
                        processedImage = resizeImageIfNeeded(image, maxDimension: maxDimension)
                    }

                    DispatchQueue.main.async {
                        self.parent.image = processedImage
                        self.parent.showingCropView = true
                    }
                }
            }
            DispatchQueue.main.async {
                self.parent.dismiss()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            DispatchQueue.main.async {
                self.parent.dismiss()
            }
        }
    }
}

// MARK: - Image Crop View
struct ImageCropView: View {
    let image: UIImage
    @Binding var croppedImage: Image?
    @Binding var isPresented: Bool
    var onComplete: ((UIImage) -> Void)?

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var cropDiameter: CGFloat = 260
    @State private var imageSize: CGSize = .zero

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let availableHeight = geometry.size.height
                let controlsHeight: CGFloat = 180
                let cropAreaSize = max(180, min(availableWidth - 40, availableHeight - controlsHeight))
                let circleSize = min(cropAreaSize * 0.85, 220)
                let cropContainerHeight = max(cropAreaSize, availableHeight - controlsHeight)

                VStack(spacing: 0) {
                    ZStack {
                        Color.black

                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(
                                width: calculateImageSize().width,
                                height: calculateImageSize().height
                            )
                            .scaleEffect(scale)
                            .offset(offset)
                            .onAppear {
                                setupInitialImageSize(cropDiameter: circleSize)
                                scale = 1.0
                                lastScale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale = max(0.5, min(3.0, scale * delta))
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    }
                            )

                        Color.black.opacity(0.55)
                            .overlay(
                                Circle()
                                    .frame(width: circleSize, height: circleSize)
                                    .blendMode(.destinationOut)
                            )
                            .compositingGroup()
                            .allowsHitTesting(false)

                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: circleSize, height: circleSize)
                            .allowsHitTesting(false)

                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            .frame(width: circleSize, height: circleSize)
                            .overlay(
                                ZStack {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 0.5, height: circleSize)
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: circleSize, height: 0.5)
                                }
                            )
                            .allowsHitTesting(false)
                    }
                    .frame(width: cropAreaSize, height: cropAreaSize)
                    .frame(maxWidth: .infinity, maxHeight: cropContainerHeight, alignment: .top)
                    .padding(.top, Spacing.lg)

                    VStack(spacing: Spacing.lg) {
                        HStack(spacing: Spacing.xl) {
                            Button(action: {
                                withAnimation {
                                    scale = max(0.6, scale - 0.1)
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }

                            Slider(value: $scale, in: 0.6...3.0)
                                .accentColor(.white)

                            Button(action: {
                                withAnimation {
                                    scale = min(3.0, scale + 0.1)
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, Spacing.xl)

                        Text("拖动和缩放图片以调整位置")
                            .font(.bodySmall)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.vertical, Spacing.xl)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.82))
                }
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .principal) {
                    Text("调整头像")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        if let croppedUIImage = cropImage() {
                            croppedImage = Image(uiImage: croppedUIImage)
                            onComplete?(croppedUIImage)
                        }
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                }
            }
        }
    }

    private func setupInitialImageSize(cropDiameter: CGFloat) {
        let imageAspectRatio = image.size.width / image.size.height
        let cropAspectRatio: CGFloat = 1.0 // 圆形裁剪框是正方形

        var width: CGFloat
        var height: CGFloat

        if imageAspectRatio > cropAspectRatio {
            // 图片比裁剪框更宽，以高度为准
            height = cropDiameter
            width = height * imageAspectRatio
        } else {
            // 图片比裁剪框更高，以宽度为准
            width = cropDiameter
            height = width / imageAspectRatio
        }

        self.imageSize = CGSize(width: width, height: height)
        self.cropDiameter = cropDiameter
    }

    private func calculateImageSize() -> CGSize {
        if imageSize == .zero {
            return CGSize(width: cropDiameter, height: cropDiameter)
        }
        return imageSize
    }

    private func cropImage() -> UIImage? {
        // 输出大小
        let outputSize = CGSize(width: 200, height: 200) // 减小输出尺寸以提高性能

        // 创建图像渲染器
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0 // 固定使用2x分辨率
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)

        let croppedUIImage = renderer.image { context in
            // 设置圆形裁剪路径
            let clipPath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: outputSize))
            clipPath.addClip()

            // 计算图片在裁剪框中的位置
            let scaledImageSize = CGSize(
                width: imageSize.width * scale,
            height: imageSize.height * scale
        )

        // 计算绘制位置（基于300的裁剪框大小）
        let effectiveDiameter = cropDiameter > 0 ? cropDiameter : 260
        let scaleFactor = outputSize.width / effectiveDiameter
        let drawX = (outputSize.width - scaledImageSize.width * scaleFactor) / 2 + (offset.width * scaleFactor)
        let drawY = (outputSize.height - scaledImageSize.height * scaleFactor) / 2 + (offset.height * scaleFactor)

        // 绘制图像
        let drawRect = CGRect(
                x: drawX,
                y: drawY,
                width: scaledImageSize.width * scaleFactor,
                height: scaledImageSize.height * scaleFactor
            )

            image.draw(in: drawRect)
        }

        return croppedUIImage
    }
}

private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat = 1200) -> UIImage {
    let maxSide = max(image.size.width, image.size.height)
    guard maxSide > maxDimension else { return image }

    let scale = maxDimension / maxSide
    let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    let renderer = UIGraphicsImageRenderer(size: newSize)
    return renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: newSize))
    }
}

private func downsampleImage(data: Data, maxDimension: CGFloat) -> UIImage? {
    autoreleasepool {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]

        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
            return UIImage(data: data)
        }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]

        if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) {
            return UIImage(cgImage: cgImage)
        }

        return UIImage(data: data)
    }
}

private let imageProcessingQueue = DispatchQueue(label: "com.safedrivernote.imageProcessing", qos: .userInitiated)

#Preview {
    UserProfileView()
        .environmentObject(AppDI.shared)
}
