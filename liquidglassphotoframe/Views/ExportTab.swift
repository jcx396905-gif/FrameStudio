import SwiftUI

struct ExportTab: View {
    @Binding var config: FrameConfig
    let image: UIImage?
    let isExporting: Bool
    let exportMessage: String?
    let onExport: () -> Void
    let onSaveConfig: () -> Void
    let onResetConfig: () -> Void
    @State private var showSettings = false
    @State private var authorTapCount = 0
    @AppStorage("language") private var language: String = "zh"
    @AppStorage("colorScheme") private var colorScheme: String = "dark"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(L.t("导出", "Export"))

            Button {
                onExport()
            } label: {
                HStack(spacing: 8) {
                    if isExporting { ProgressView().tint(.black) }
                    Image(systemName: "square.and.arrow.up").font(.system(size: 16, weight: .semibold))
                    Text(isExporting ? L.t("导出中...", "Exporting...") : L.t("导出相框", "Export Frame")).font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "#D4A853").opacity(isExporting ? 0.5 : 1)))
            }
            .disabled(image == nil || isExporting)

            groupBox {
                Text(L.t("格式", "Format")).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
                GlassSegmentedPicker(selection: $config.exportFormat, options: ExportFormat.allCases)
            }

            if config.exportFormat != .png {
                groupBox {
                    GlassSlider(
                        value: Binding(get: { config.exportQuality }, set: { config.exportQuality = $0 }),
                        range: 0.1...1.0, label: L.t("质量", "Quality"), format: "%.0f%%")
                }
            }

            if let msg = exportMessage {
                Text(msg).font(.system(size: 11)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center).padding(.top, 4)
            }

            groupBox {
                Text(L.t("默认配置", "Default Preset"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Button {
                        onSaveConfig()
                    } label: {
                        Label(L.t("保存当前配置", "Save Preset"), systemImage: "tray.and.arrow.down")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))

                    Button {
                        onResetConfig()
                    } label: {
                        Label(L.t("恢复默认", "Reset"), systemImage: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
                }
            }

            Button {
                showSettings = true
            } label: {
                HStack {
                    Image(systemName: "gearshape").font(.system(size: 13))
                    Text(L.t("设置", "Settings")).font(.system(size: 12, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 10))
                }
                .foregroundStyle(.secondary)
                .padding(12)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 12)
        .sheet(isPresented: $showSettings) {
            VStack(spacing: 24) {
                Image(systemName: "gearshape.fill").font(.system(size: 40)).foregroundStyle(.secondary)
                Text("Frame Studio").font(.system(size: 22, weight: .bold)).foregroundStyle(.primary)

                HStack {
                    Text(L.t("语言", "Language")).foregroundStyle(.secondary)
                    Spacer()
                    Picker("", selection: $language) {
                        Text("中文").tag("zh")
                        Text("English").tag("en")
                    }
                    .pickerStyle(.segmented).frame(width: 140)
                }
                .font(.system(size: 14)).padding(.horizontal, 20)

                HStack {
                    Text(L.t("主题", "Theme")).foregroundStyle(.secondary)
                    Spacer()
                    Picker("", selection: $colorScheme) {
                        Text(L.t("浅色", "Light")).tag("light")
                        Text(L.t("深色", "Dark")).tag("dark")
                    }
                    .pickerStyle(.segmented).frame(width: 140)
                }
                .font(.system(size: 14)).padding(.horizontal, 20)

                VStack(spacing: 8) {
                    HStack { Text(L.t("版本", "Version")).foregroundStyle(.secondary); Spacer(); Text("1.0.0").foregroundStyle(.primary) }
                    HStack { Text(L.t("作者", "Author")).foregroundStyle(.secondary); Spacer(); Button("jcx") { authorTapCount += 1 }.foregroundStyle(.primary).buttonStyle(.plain) }
                }
                .font(.system(size: 14)).padding(20)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                Button { showSettings = false } label: {
                    Text(L.t("关闭", "Close")).font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                }
                .buttonStyle(.glassProminent)
            }
            .padding(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground).ignoresSafeArea())
            .presentationDetents([.medium])
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title).font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.tertiary).kerning(2).textCase(.uppercase)
    }

    @ViewBuilder
    private func groupBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) { content() }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.primary.opacity(0.035)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}
