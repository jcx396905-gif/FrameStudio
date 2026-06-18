import SwiftUI

enum AppTab: String, CaseIterable {
    case layout = "layout"
    case styleParams = "styleParams"
    case export = "export"

    var displayName: String {
        switch self {
        case .layout: return L.t("布局", "Layout")
        case .styleParams: return L.t("质感参数", "Style")
        case .export: return L.t("导出", "Export")
        }
    }

    var icon: String {
        switch self {
        case .layout: return "rectangle.3.group"
        case .styleParams: return "textformat.alt"
        case .export: return "square.and.arrow.up"
        }
    }
}

struct GlassTabBar<Content: View>: View {
    @Binding var selectedTab: AppTab
    @Namespace private var ns
    @ViewBuilder let content: (AppTab) -> Content

    var body: some View {
        VStack(spacing: 0) {
            content(selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            GlassEffectContainer(spacing: 0) {
                HStack(spacing: 4) {
                    ForEach(AppTab.allCases, id: \.self) { tab in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 16, weight: .medium))
                                Text(tab.displayName)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .foregroundStyle(selectedTab == tab ? .primary : .tertiary)
                            .background {
                                if selectedTab == tab {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.10))
                                        .matchedGeometryEffect(id: "tab", in: ns)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .glassEffectID(tab.rawValue, in: ns)
                    }
                }
                .padding(5)
                .glassEffect(.regular.tint(Color.primary.opacity(0.05)).interactive(), in: Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}
