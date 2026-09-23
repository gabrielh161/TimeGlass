import SwiftUI
import AppKit

enum ProjectColor {
    /// Punchier, higher-contrast palette than the original ~10 pastel tones. Each entry has a
    /// hand-picked light-mode and dark-mode hex value so every color stays vivid and readable
    /// against both a light and a dark Liquid Glass background, rather than relying on the
    /// system to auto-adjust a single fixed color (which tends to look muddy in dark mode).
    private static let palette: [(light: String, dark: String)] = [
        ("#0A6CFF", "#5B9DFF"), // electric blue
        ("#8B2FE0", "#B98CFF"), // vivid purple
        ("#E0157A", "#FF6FB0"), // hot pink
        ("#FF7A00", "#FFA84C"), // tangerine
        ("#C79A00", "#FFD34D"), // gold
        ("#049B5D", "#3EE39A"), // emerald
        ("#009DA6", "#3EE0EA"), // teal
        ("#4A3AE0", "#9C90FF"), // indigo
        ("#E0192F", "#FF6B7A"), // crimson
        ("#5E9A00", "#A6E22E"), // lime
        ("#FF5A4E", "#FF9186"), // coral
        ("#B41BB4", "#F07AF0"), // magenta
        ("#0091FF", "#66C2FF"), // sky
        ("#A85E00", "#E0A24D"), // amber
        ("#5D5FEF", "#ADAFFF"), // slate violet
        ("#0F8B8B", "#4DD6D6"), // deep cyan
    ]

    static func color(for project: Project) -> Color {
        let hash = project.name.unicodeScalars.reduce(into: 0) { partial, scalar in
            partial = (partial &* 31) &+ Int(scalar.value)
        }
        let index = abs(hash) % palette.count
        return adaptiveColor(palette[index])
    }

    private static func adaptiveColor(_ swatch: (light: String, dark: String)) -> Color {
        Color(NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(hex: isDark ? swatch.dark : swatch.light)
        })
    }
}

private extension NSColor {
    convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&value)
        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}
