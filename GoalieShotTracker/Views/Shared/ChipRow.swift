import SwiftUI

/// Horizontal scrolling row of selectable chips, used for the shot-type and
/// strength-state pickers in the live logger where a `Picker` would be too
/// slow to tap through mid-game.
struct ChipRow<T: Identifiable & Hashable>: View {
    let items: [T]
    @Binding var selection: T
    let label: (T) -> String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { item in
                    let isSelected = item == selection
                    Button {
                        selection = item
                    } label: {
                        Text(label(item))
                            .font(.subheadline.weight(isSelected ? .semibold : .regular))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(isSelected ? Theme.iceBlue : Theme.cardBackground)
                            )
                            .foregroundStyle(isSelected ? Color.black : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1)
        }
    }
}
