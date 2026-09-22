import SwiftUI

enum ProjectColor {
    private static let palette: [Color] = [
        .blue, .purple, .pink, .orange, .yellow, .mint, .teal, .indigo, .cyan, .red
    ]

    static func color(for project: Project) -> Color {
        let hash = project.name.unicodeScalars.reduce(into: 0) { partial, scalar in
            partial = (partial &* 31) &+ Int(scalar.value)
        }
        let index = abs(hash) % palette.count
        return palette[index]
    }
}
