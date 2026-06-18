import SwiftUI

struct GlassSlider: View {
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let label: String
    let format: String

    private var displayValue: CGFloat {
        format.contains("%%") ? value * 100 : value
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: format, displayValue))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            Slider(value: $value, in: range)
                .tint(Color(hex: "#D4A853").opacity(0.75))
                .background(
                    Capsule()
                        .fill(Color.primary.opacity(0.07))
                        .frame(height: 4)
                )
        }
    }
}
