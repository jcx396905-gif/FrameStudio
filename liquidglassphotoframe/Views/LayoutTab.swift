import SwiftUI
import PhotosUI

struct LayoutTab: View {
    @Binding var config: FrameConfig
    @Binding var selectedPhotoItem: PhotosPickerItem?
    let showsPhotoPicker: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(L.t("布局", "Layout"))

            if showsPhotoPicker {
                groupBox {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 16, weight: .semibold))
                            Text(L.t("选择照片", "Select Photo"))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            groupBox {
                Text(L.t("背景模式", "Background"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                GlassSegmentedPicker(
                    selection: $config.backgroundMode,
                    options: BackgroundMode.allCases
                )
            }

            groupBox {
                GlassSlider(value: $config.blurRadius, range: 0...100, label: L.t("模糊", "Blur"), format: "%.0f")
                GlassSlider(value: $config.photoScale, range: 0.72...0.94, label: L.t("照片宽度", "Photo Width"), format: "%.0f%%")
                GlassSlider(value: $config.cornerRadiusScale, range: 0...0.04, label: L.t("圆角", "Radius"), format: "%.0f%%")
                GlassSlider(value: $config.shadowDepth, range: 0...1, label: L.t("阴影", "Shadow"), format: "%.0f%%")
            }
        }
        .padding(.top, 12)
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: showsPhotoPicker)
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .kerning(2).textCase(.uppercase)
    }

    @ViewBuilder
    private func groupBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) { content() }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.primary.opacity(0.035)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}
