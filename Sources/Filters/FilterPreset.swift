import Foundation

enum GrainStyle: String, Codable, CaseIterable, Identifiable {
    case fine35mm = "35mm Fine"
    case coarseFilm = "Coarse Film"
    case ccdLuminance = "CCD Luma"
    case ccdChroma = "CCD Chroma"
    case organicRandom = "Organic"
    case digitalSensor = "Sensor"

    var id: String { rawValue }
}

struct FilterParameters: Codable, Equatable {
    var intensity: Double          // 0.0 ... 1.0
    var exposure: Double           // -2.0 ... 2.0 EV
    var contrast: Double           // 0.5 ... 1.6
    var saturation: Double         // 0.0 ... 1.8
    var temperature: Double        // -1500 ... +1500 Kelvin shift
    var tint: Double               // -50 ... +50
    var highlights: Double         // -1.0 ... 1.0
    var shadows: Double            // -1.0 ... 1.0
    var fade: Double               // 0.0 ... 0.35 (lifted black point)
    var grainStyle: GrainStyle
    var grainIntensity: Double     // 0.0 ... 1.0
    var grainSize: Double          // 0.5 ... 2.5
    var colorNoise: Double         // 0.0 ... 1.0
    var grainRoughness: Double     // 0.0 ... 1.0
    var bloom: Double              // 0.0 ... 1.0
    var halation: Double           // 0.0 ... 1.0
    var vignette: Double           // 0.0 ... 1.0
    var sharpness: Double          // -1.0 ... 1.0
    var chromaticAberration: Double // 0.0 ... 1.0

    static let neutral = FilterParameters(
        intensity: 1.0,
        exposure: 0.0,
        contrast: 1.0,
        saturation: 1.0,
        temperature: 0.0,
        tint: 0.0,
        highlights: 0.0,
        shadows: 0.0,
        fade: 0.0,
        grainStyle: .digitalSensor,
        grainIntensity: 0.0,
        grainSize: 1.0,
        colorNoise: 0.0,
        grainRoughness: 0.5,
        bloom: 0.0,
        halation: 0.0,
        vignette: 0.0,
        sharpness: 0.0,
        chromaticAberration: 0.0
    )
}

struct FilterPreset: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var code: String
    var isBuiltIn: Bool
    var parameters: FilterParameters
}
