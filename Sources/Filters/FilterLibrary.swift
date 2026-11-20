import Foundation
import SwiftUI

@MainActor
final class FilterLibrary: ObservableObject {
    @Published var presets: [FilterPreset] = []
    @Published var selectedPresetID: String = "iphone_5s"
    @Published var activeParameters: FilterParameters

    private let customStorageKey = "digicam.custom.presets.v1"

    static let builtInPresets: [FilterPreset] = [
        FilterPreset(
            id: "iphone_5s",
            name: "iPhone 5S",
            code: "5S",
            isBuiltIn: true,
            parameters: FilterParameters(
                intensity: 1.0,
                exposure: -0.05,
                contrast: 1.06,
                saturation: 0.96,
                temperature: 260,
                tint: 4,
                highlights: -0.18,
                shadows: -0.10,
                fade: 0.02,
                grainStyle: .digitalSensor,
                grainIntensity: 0.16,
                grainSize: 0.85,
                colorNoise: 0.08,
                grainRoughness: 0.35,
                bloom: 0.06,
                halation: 0.0,
                vignette: 0.12,
                sharpness: -0.08,
                chromaticAberration: 0.04
            )
        ),
        FilterPreset(
            id: "ccd_flash",
            name: "CCD Flash",
            code: "CCD",
            isBuiltIn: true,
            parameters: FilterParameters(
                intensity: 1.0,
                exposure: 0.12,
                contrast: 1.24,
                saturation: 1.14,
                temperature: -220,
                tint: -6,
                highlights: 0.22,
                shadows: -0.26,
                fade: 0.0,
                grainStyle: .ccdChroma,
                grainIntensity: 0.34,
                grainSize: 1.15,
                colorNoise: 0.45,
                grainRoughness: 0.65,
                bloom: 0.18,
                halation: 0.04,
                vignette: 0.28,
                sharpness: 0.15,
                chromaticAberration: 0.18
            )
        ),
        FilterPreset(
            id: "golden_haze",
            name: "Golden Haze",
            code: "GOLD",
            isBuiltIn: true,
            parameters: FilterParameters(
                intensity: 1.0,
                exposure: 0.08,
                contrast: 0.88,
                saturation: 1.08,
                temperature: 620,
                tint: 10,
                highlights: 0.16,
                shadows: 0.08,
                fade: 0.07,
                grainStyle: .fine35mm,
                grainIntensity: 0.22,
                grainSize: 1.05,
                colorNoise: 0.12,
                grainRoughness: 0.45,
                bloom: 0.48,
                halation: 0.32,
                vignette: 0.18,
                sharpness: -0.18,
                chromaticAberration: 0.10
            )
        ),
        FilterPreset(
            id: "cold_memory",
            name: "Cold Memory",
            code: "COLD",
            isBuiltIn: true,
            parameters: FilterParameters(
                intensity: 1.0,
                exposure: -0.08,
                contrast: 0.94,
                saturation: 0.76,
                temperature: -540,
                tint: -8,
                highlights: -0.14,
                shadows: 0.05,
                fade: 0.11,
                grainStyle: .organicRandom,
                grainIntensity: 0.30,
                grainSize: 1.20,
                colorNoise: 0.18,
                grainRoughness: 0.60,
                bloom: 0.10,
                halation: 0.0,
                vignette: 0.24,
                sharpness: -0.12,
                chromaticAberration: 0.12
            )
        ),
        FilterPreset(
            id: "digicam_2005",
            name: "Digicam 2005",
            code: "2005",
            isBuiltIn: true,
            parameters: FilterParameters(
                intensity: 1.0,
                exposure: 0.05,
                contrast: 1.18,
                saturation: 1.22,
                temperature: 140,
                tint: 12,
                highlights: 0.25,
                shadows: -0.18,
                fade: 0.01,
                grainStyle: .ccdLuminance,
                grainIntensity: 0.44,
                grainSize: 1.35,
                colorNoise: 0.52,
                grainRoughness: 0.78,
                bloom: 0.22,
                halation: 0.08,
                vignette: 0.22,
                sharpness: 0.22,
                chromaticAberration: 0.26
            )
        ),
        FilterPreset(
            id: "soft_film",
            name: "Soft Film",
            code: "FILM",
            isBuiltIn: true,
            parameters: FilterParameters(
                intensity: 1.0,
                exposure: 0.04,
                contrast: 0.92,
                saturation: 0.93,
                temperature: 190,
                tint: 6,
                highlights: -0.24,
                shadows: 0.10,
                fade: 0.06,
                grainStyle: .fine35mm,
                grainIntensity: 0.24,
                grainSize: 0.95,
                colorNoise: 0.10,
                grainRoughness: 0.40,
                bloom: 0.14,
                halation: 0.12,
                vignette: 0.10,
                sharpness: -0.15,
                chromaticAberration: 0.03
            )
        )
    ]

    init() {
        let initial = Self.builtInPresets[0]
        self.activeParameters = initial.parameters
        reloadPresets()
    }

    var currentPreset: FilterPreset {
        presets.first(where: { $0.id == selectedPresetID }) ?? Self.builtInPresets[0]
    }

    func selectPreset(_ preset: FilterPreset) {
        selectedPresetID = preset.id
        activeParameters = preset.parameters
    }

    func resetCurrentPreset() {
        activeParameters = currentPreset.parameters
    }

    func saveCustomPreset(name: String, parameters: FilterParameters) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var customList = loadCustomFilters()
        let entry = CustomFilter(id: UUID(), name: trimmed, createdAt: Date(), parameters: parameters)
        customList.append(entry)
        persistCustomFilters(customList)
        reloadPresets()
        selectedPresetID = entry.id.uuidString
        activeParameters = parameters
    }

    func deleteCustomPreset(id: String) {
        var customList = loadCustomFilters()
        customList.removeAll { $0.id.uuidString == id }
        persistCustomFilters(customList)
        reloadPresets()
        if selectedPresetID == id {
            selectPreset(Self.builtInPresets[0])
        }
    }

    private func reloadPresets() {
        let customPresets = loadCustomFilters().map { $0.asPreset() }
        presets = Self.builtInPresets + customPresets
    }

    private func loadCustomFilters() -> [CustomFilter] {
        guard let data = UserDefaults.standard.data(forKey: customStorageKey),
              let decoded = try? JSONDecoder().decode([CustomFilter].self, from: data) else {
            return []
        }
        return decoded
    }

    private func persistCustomFilters(_ list: [CustomFilter]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: customStorageKey)
        }
    }
}
