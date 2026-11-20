import SwiftUI

enum RetroTheme {
    static let background = Color.black
    static let surface = Color(white: 0.10)
    static let elevatedSurface = Color(white: 0.16)
    static let hairline = Color.white.opacity(0.16)
    static let mutedText = Color(white: 0.58)
    static let amberAccent = Color(red: 1.0, green: 0.80, blue: 0.18)

    static func monoLabel(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static func uiLabel(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}
