import SwiftUI

struct FilterSelector: View {
    @ObservedObject var filterLibrary: FilterLibrary
    let onFilterChanged: (FilterPreset) -> Void
    let onOpenEditor: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(filterLibrary.presets) { preset in
                        let isSelected = preset.id == filterLibrary.selectedPresetID
                        Button {
                            filterLibrary.selectPreset(preset)
                            onFilterChanged(preset)
                        } label: {
                            VStack(spacing: 3) {
                                Text(preset.code)
                                    .font(RetroTheme.monoLabel(11, weight: .bold))
                                    .foregroundColor(isSelected ? .black : .white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(isSelected ? RetroTheme.amberAccent : RetroTheme.surface)

                                Text(preset.name.uppercased())
                                    .font(RetroTheme.monoLabel(9, weight: isSelected ? .semibold : .regular))
                                    .foregroundColor(isSelected ? RetroTheme.amberAccent : RetroTheme.mutedText)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }

            HStack(spacing: 12) {
                TactileSlider(
                    label: "INTENSITY",
                    value: $filterLibrary.activeParameters.intensity,
                    range: 0...1,
                    format: "%.2f"
                )

                TactileSlider(
                    label: "GRAIN",
                    value: $filterLibrary.activeParameters.grainIntensity,
                    range: 0...1,
                    format: "%.2f"
                )
            }
            .padding(.horizontal, 16)

            HStack {
                Button {
                    filterLibrary.resetCurrentPreset()
                    onFilterChanged(filterLibrary.currentPreset)
                } label: {
                    Text("RESET")
                        .font(RetroTheme.monoLabel(10, weight: .semibold))
                        .foregroundColor(RetroTheme.mutedText)
                }

                Spacer()

                Button {
                    onOpenEditor()
                } label: {
                    Label("CUSTOMIZE & SAVE", systemImage: "slider.horizontal.3")
                        .font(RetroTheme.monoLabel(10, weight: .semibold))
                        .foregroundColor(RetroTheme.amberAccent)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.88))
    }
}
