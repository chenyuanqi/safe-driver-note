import SwiftUI

// 图片包装器，用于提供稳定的ID
private struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

// 简化的图片选择视图
struct PhotoSelectionView: View {
    @Binding var selectedImages: [UIImage]
    @Binding var showingPhotoPicker: Bool

    let maxImages = 9

    // 创建带有稳定ID的图片数组
    @State private var identifiableImages: [IdentifiableImage] = []

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // 图片缩略图网格
            if !identifiableImages.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80, maximum: 80))
                ], spacing: Spacing.md) {
                    ForEach(identifiableImages) { item in
                        PhotoThumbnailView(
                            image: item.image,
                            onDelete: {
                                // 从identifiableImages中删除
                                if let index = identifiableImages.firstIndex(where: { $0.id == item.id }) {
                                    identifiableImages.remove(at: index)
                                    // 同步更新selectedImages
                                    selectedImages = identifiableImages.map { $0.image }
                                }
                            }
                        )
                    }
                }
            }

            // 添加图片按钮
            if identifiableImages.count < maxImages {
                Button(action: {
                    showingPhotoPicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text(identifiableImages.isEmpty ? "添加图片" : "添加更多")
                        Spacer()
                        Text("\(identifiableImages.count)/\(maxImages)")
                            .font(.caption)
                            .foregroundColor(.brandSecondary500)
                    }
                    .foregroundColor(.brandPrimary500)
                    .padding(.vertical, Spacing.md)
                    .padding(.horizontal, Spacing.lg)
                    .background(Color.brandPrimary50)
                    .cornerRadius(CornerRadius.md)
                }
            }
        }
        .onAppear {
            // 初始化时同步selectedImages到identifiableImages
            if identifiableImages.isEmpty && !selectedImages.isEmpty {
                identifiableImages = selectedImages.map { IdentifiableImage(image: $0) }
            }
        }
        .onChange(of: selectedImages) { _, newImages in
            // 当selectedImages从外部改变时（如从相册选择新图片）
            // 检查是否需要添加新图片
            if newImages.count > identifiableImages.count {
                // 找出新添加的图片
                let currentImages = identifiableImages.map { $0.image }
                for image in newImages {
                    // 简单比较：如果这个图片不在当前列表中，就添加
                    if !currentImages.contains(where: { $0 === image }) {
                        identifiableImages.append(IdentifiableImage(image: image))
                    }
                }
            } else if newImages.count < identifiableImages.count {
                // 如果selectedImages减少了（可能从外部删除），同步更新
                identifiableImages = newImages.map { IdentifiableImage(image: $0) }
            } else if newImages.isEmpty {
                // 如果清空了，也清空identifiableImages
                identifiableImages = []
            }
        }
    }
}