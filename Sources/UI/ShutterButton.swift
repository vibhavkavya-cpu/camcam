import SwiftUI
import UIKit

struct ShutterButton: View {
    let isCapturing: Bool
    let action: () -> Void

    @State private var isPressed = false
    private let impact = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        Button {
            impact.prepare()
            impact.impactOccurred()
            action()
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 3.5)
                    .frame(width: 72, height: 72)

                Circle()
                    .fill(isCapturing ? RetroTheme.amberAccent : Color.white)
                    .frame(width: 60, height: 60)
                    .scaleEffect(isPressed ? 0.90 : 1.0)
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeOut(duration: 0.08)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.12)) { isPressed = false }
                }
        )
        .disabled(isCapturing)
    }
}
