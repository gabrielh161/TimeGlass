import SwiftUI

struct PulsingDot: View {
    var color: Color = .green
    var size: CGFloat = 7
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.55))
                .frame(width: size, height: size)
                .scaleEffect(animate ? 2.4 : 1)
                .opacity(animate ? 0 : 0.7)
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.3).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }
}
