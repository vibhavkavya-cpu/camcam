import SwiftUI

struct FocusReticleView: View {
    let point: CGPoint
    @Binding var exposureBias: Float
    let minBias: Float
    let maxBias: Float
    let onBiasChanged: (Float) -> Void

    @State private var pulseScale: CGFloat = 1.25
    @State private var dragStartBias: Float = 0.0

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Rectangle()
                    .stroke(RetroTheme.amberAccent, lineWidth: 1.25)
                    .frame(width: 72, height: 72)

                VStack {
                    Rectangle().fill(RetroTheme.amberAccent).frame(width: 1, height: 5)
                    Spacer()
                    Rectangle().fill(RetroTheme.amberAccent).frame(width: 1, height: 5)
                }
                .frame(height: 72)

                HStack {
                    Rectangle().fill(RetroTheme.amberAccent).frame(width: 5, height: 1)
                    Spacer()
                    Rectangle().fill(RetroTheme.amberAccent).frame(width: 5, height: 1)
                }
                .frame(width: 72)
            }
            .scaleEffect(pulseScale)

            VStack(spacing: 4) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 13))
                    .foregroundColor(RetroTheme.amberAccent)

                GeometryReader { geo in
                    let norm = CGFloat((exposureBias - minBias) / max(0.01, maxBias - minBias))
                    let yPos = (1.0 - max(0, min(1, norm))) * geo.size.height

                    ZStack(alignment: .top) {
                        Rectangle()
                            .fill(RetroTheme.amberAccent.opacity(0.35))
                            .frame(width: 1.5, height: geo.size.height)
                            .frame(maxWidth: .infinity)

                        Circle()
                            .fill(RetroTheme.amberAccent)
                            .frame(width: 10, height: 10)
                            .offset(y: max(0, min(geo.size.height - 10, yPos - 5)))
                    }
                }
                .frame(width: 18, height: 76)
            }
        }
        .position(x: point.x + 14, y: point.y)
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    let delta = Float(-value.translation.height / 90.0) * (maxBias - minBias) * 0.5
                    let next = max(minBias, min(maxBias, dragStartBias + delta))
                    onBiasChanged(next)
                }
                .onEnded { _ in
                    dragStartBias = exposureBias
                }
        )
        .onAppear {
            dragStartBias = exposureBias
            withAnimation(.easeOut(duration: 0.2)) {
                pulseScale = 1.0
            }
        }
    }
}
