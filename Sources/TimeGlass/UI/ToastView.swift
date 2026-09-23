import SwiftUI

/// Content view for the brief start/stop confirmation overlay shown by ToastWindowController.
struct ToastView: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .font(.system(size: 14, weight: .semibold))
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minWidth: 200, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
    }
}
