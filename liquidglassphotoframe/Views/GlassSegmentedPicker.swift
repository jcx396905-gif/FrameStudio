import SwiftUI

struct GlassSegmentedPicker<T: Hashable & CustomStringConvertible>: View {
    @Binding var selection: T
    let options: [T]
    @Namespace private var ns

    var body: some View {
        GlassEffectContainer(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(options, id: \.self) { option in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selection = option
                        }
                    } label: {
                        Text(option.description)
                            .font(.system(size: 11, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(selection == option ? .primary : .tertiary)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)
                    .glassEffectID(String(describing: option), in: ns)
                }
            }
            .padding(3)
            .glassEffect(.regular.tint(Color.primary.opacity(0.04)), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
