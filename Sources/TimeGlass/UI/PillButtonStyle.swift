import SwiftUI

struct PillButtonStyle: ButtonStyle {
    var tint: Color = .accentColor

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [tint.opacity(configuration.isPressed ? 0.7 : 0.95), tint],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: Capsule()
            )
            .foregroundStyle(.white)
    }
}

extension ButtonStyle where Self == PillButtonStyle {
    static var pill: PillButtonStyle { PillButtonStyle() }
    static func pill(tint: Color) -> PillButtonStyle { PillButtonStyle(tint: tint) }
}
