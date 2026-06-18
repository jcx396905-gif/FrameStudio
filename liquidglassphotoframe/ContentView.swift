//
//  ContentView.swift
//  liquidglassphotoframe
//
//  Created by 嘻嘻 on 2026/5/23.
//

import SwiftUI
import PhotosUI
import OSLog

private let log = Logger(subsystem: "x.liquidglassphotoframe", category: "app")

struct ContentView: View {
    @State private var config = FrameConfigStore.load()
    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var rawPhotoData: Data?
    @State private var selectedTab: AppTab = .layout
    @State private var isExporting = false
    @State private var exportMessage: String?
    @State private var showStatusToast = false
    @AppStorage("colorScheme") private var colorScheme: String = "dark"
    @AppStorage("language") private var language: String = "zh"

    private var bgColor: Color {
        colorScheme == "light"
            ? Color(red: 0.98, green: 0.96, blue: 0.92)
            : Color(uiColor: .systemBackground)
    }

    var body: some View {
        GeometryReader { geometry in
            let previewWidth = geometry.size.width * 0.88

            ZStack {
                bgColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    previewStage(geometry: geometry, previewWidth: previewWidth)

                    GlassTabBar(selectedTab: $selectedTab) { tab in
                        ScrollView {
                            VStack(spacing: 0) {
                                switch tab {
                                case .layout:
                                    LayoutTab(
                                        config: $config,
                                        selectedPhotoItem: $selectedPhotoItem,
                                        showsPhotoPicker: selectedImage != nil
                                    )
                                case .styleParams:
                                    StyleParamsTab(
                                        config: $config,
                                        rawPhotoData: rawPhotoData
                                    )
                                case .export:
                                    ExportTab(
                                        config: $config,
                                        image: selectedImage,
                                        isExporting: isExporting,
                                        exportMessage: exportMessage,
                                        onExport: { exportImage(previewWidth: previewWidth) },
                                        onSaveConfig: { saveCurrentConfig(showMessage: true) },
                                        onResetConfig: resetConfig
                                    )
                                }
                            }
                            .padding(.bottom, 92)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                    }
                }

                if showStatusToast, let exportMessage {
                    statusToast(exportMessage)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedImage)
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: showStatusToast)
        }
        .preferredColorScheme(colorScheme == "light" ? .light : .dark)
        .onChange(of: selectedPhotoItem) { _, newItem in
            loadPhoto(newItem)
        }
        .onChange(of: config.persistenceSignature) { _, _ in
            FrameConfigStore.save(config)
        }
    }

    @ViewBuilder
    private func previewStage(geometry: GeometryProxy, previewWidth: CGFloat) -> some View {
        let stageWidth = geometry.size.width - 20
        let stageHeight = previewStageHeight(stageWidth: stageWidth, screenHeight: geometry.size.height)

        ZStack(alignment: .topTrailing) {
            if selectedImage == nil {
                EmptyPhotoStage(selectedPhotoItem: $selectedPhotoItem)
                    .transition(.opacity)
            } else {
                FramePreviewView(image: selectedImage, config: config)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            quickExportButton(previewWidth: previewWidth)
                .padding(.top, 14)
                .padding(.trailing, 16)
                .opacity(selectedImage == nil ? 0 : 1)
                .allowsHitTesting(selectedImage != nil)
        }
        .frame(height: stageHeight)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 10)
        .padding(.top, geometry.safeAreaInsets.top + 8)
    }

    private func previewStageHeight(stageWidth: CGFloat, screenHeight: CGFloat) -> CGFloat {
        guard let selectedImage else {
            return max(screenHeight * 0.30, 230)
        }
        let naturalHeight = FrameRenderLayout.make(
            canvasWidth: stageWidth,
            imageSize: selectedImage.size,
            config: config
        ).canvasSize.height
        let minHeight = max(screenHeight * 0.28, 230)
        let maxHeight = screenHeight * 0.44
        return min(max(naturalHeight, minHeight), maxHeight)
    }

    private func quickExportButton(previewWidth: CGFloat) -> some View {
        Button {
            exportImage(previewWidth: previewWidth)
        } label: {
            ZStack {
                if isExporting {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.primary)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .frame(width: 50, height: 50)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(selectedImage == nil || isExporting)
        .glassEffect(.regular.tint(Color(hex: "#D4A853").opacity(0.28)).interactive(), in: Circle())
        .accessibilityLabel(L.t("一键导出", "Quick Export"))
    }

    private func statusToast(_ message: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: message.contains(L.t("失败", "Failed")) ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .foregroundStyle(message.contains(L.t("失败", "Failed")) ? .orange : .green)
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(2)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: Capsule())
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        Task {
            guard let item else { return }
            do {
                guard let rawData = try await item.loadTransferable(type: Data.self) else {
                    log.error("loadTransferable returned nil")
                    showTransientMessage(L.t("照片读取失败", "Photo Load Failed"))
                    return
                }
                rawPhotoData = rawData
                log.info("Photo loaded: \(rawData.count) bytes")

                guard let uiImage = UIImage(data: rawData) else {
                    log.error("UIImage(data:) returned nil for \(rawData.count) bytes")
                    showTransientMessage(L.t("照片解码失败", "Photo Decode Failed"))
                    return
                }

                selectedImage = uiImage
                selectedTab = .styleParams
                log.info("UIImage decoded: \(uiImage.size.width)x\(uiImage.size.height)")

                if let exif = ExifReaderService.extractExif(from: rawData) {
                    config.exifText = exif
                    log.info("EXIF detected: \(exif)")
                }
                if let model = ExifReaderService.extractCameraModel(from: rawData) {
                    config.cameraModel = model
                    config.cameraModelVisible = true
                    log.info("Camera model detected: \(model)")
                }
                if let brand = ExifReaderService.extractCameraBrand(from: rawData) {
                    config.selectedBrand = brand
                    config.logoVisible = true
                    log.info("Camera brand detected: \(brand), logo enabled")
                }
            } catch {
                log.error("Photo load failed: \(error.localizedDescription)")
                showTransientMessage(L.t("照片读取失败", "Photo Load Failed"))
            }
        }
    }

    private func exportImage(previewWidth: CGFloat) {
        guard let selectedImage, !isExporting else { return }
        let exportConfig = config.copy()
        FrameConfigStore.save(exportConfig)
        isExporting = true
        exportMessage = nil

        Task {
            guard let exported = await GlassExportService.exportFrame(
                image: selectedImage,
                config: exportConfig,
                previewWidth: previewWidth
            ) else {
                await MainActor.run {
                    isExporting = false
                    showTransientMessage(L.t("导出失败", "Export Failed"))
                }
                return
            }

            do {
                try await PhotoLibraryService.saveImage(
                    exported,
                    format: exportConfig.exportFormat,
                    quality: exportConfig.exportQuality
                )
                await MainActor.run {
                    isExporting = false
                    showTransientMessage(L.t("已保存到相册", "Saved to Photos"))
                }
            } catch {
                log.error("Save failed: \(error.localizedDescription)")
                await MainActor.run {
                    isExporting = false
                    showTransientMessage(L.t("保存失败", "Save Failed"))
                }
            }
        }
    }

    private func saveCurrentConfig(showMessage: Bool) {
        FrameConfigStore.save(config)
        if showMessage {
            showTransientMessage(L.t("配置已保存", "Preset Saved"))
        }
    }

    private func resetConfig() {
        config.resetToDefaults()
        FrameConfigStore.save(config)
        showTransientMessage(L.t("已恢复默认配置", "Defaults Restored"))
    }

    private func showTransientMessage(_ message: String) {
        exportMessage = message
        showStatusToast = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                showStatusToast = false
            }
        }
    }
}

private struct EmptyPhotoStage: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#D4A853").opacity(0.18),
                    Color.primary.opacity(0.04),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                VStack(spacing: 14) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 34, weight: .semibold))
                    Text(L.t("选择照片", "Select Photo"))
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}
