import SwiftUI

// 简化的图片选择视图
struct PhotoSelectionView: View {
    @Binding var selectedImages: [UIImage]
    @State private var showingPhotoPicker = false

    let maxImages = 9

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // 图片缩略图网格
            if !selectedImages.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80, maximum: 80))
                ], spacing: Spacing.md) {
                    ForEach(selectedImages.indices, id: \.self) { index in
                        PhotoThumbnailView(
                            image: selectedImages[index],
                            onDelete: {
                                selectedImages.remove(at: index)
                            }
                        )
                    }
                }
            }

            // 添加图片按钮
            if selectedImages.count < maxImages {
                Button(action: {
                    showingPhotoPicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text(selectedImages.isEmpty ? "添加图片" : "添加更多")
                        Spacer()
                        Text("\(selectedImages.count)/\(maxImages)")
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
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView(
                selectedImages: $selectedImages,
                maxSelection: maxImages - selectedImages.count
            )
        }
    }
}