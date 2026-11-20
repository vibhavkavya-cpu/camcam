import SwiftUI

struct ManualControlsView: View {
    @ObservedObject var cameraManager: CameraManager

    private var normalizedShutterBinding: Binding<Double> {
        Binding(
            get: {
                ShutterSpeedFormatter.normalized(
                    fromSeconds: cameraManager.shutterSeconds,
                    min: cameraManager.capabilities.minExposureSeconds,
                    max: cameraManager.capabilities.maxExposureSeconds
                )
            },
            set: { norm in
                let sec = ShutterSpeedFormatter.seconds(
                    fromNormalized: norm,
                    min: cameraManager.capabilities.minExposureSeconds,
                    max: cameraManager.capabilities.maxExposureSeconds
                )
                cameraManager.setManualExposure(iso: nil, shutterSeconds: sec)
            }
        )
    }

    private var isoBinding: Binding<Double> {
        Binding(
            get: { Double(cameraManager.isoValue) },
            set: { cameraManager.setManualExposure(iso: Float($0), shutterSeconds: nil) }
        )
    }

    private var evBinding: Binding<Double> {
        Binding(
            get: { Double(cameraManager.exposureBias) },
            set: { cameraManager.setExposureBias(Float($0)) }
        )
    }

    private var focusBinding: Binding<Double> {
        Binding(
            get: { Double(cameraManager.lensPosition) },
            set: { cameraManager.setManualFocus(Float($0)) }
        )
    }

    private var zoomBinding: Binding<Double> {
        Binding(
            get: { Double(cameraManager.zoomFactor) },
            set: { cameraManager.setZoom(CGFloat($0)) }
        )
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Text("WB")
                    .font(RetroTheme.monoLabel(10, weight: .bold))
                    .foregroundColor(RetroTheme.mutedText)

                if cameraManager.capabilities.supportsWhiteBalanceGains {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(WhiteBalancePreset.allCases) { preset in
                                let active = cameraManager.whiteBalancePreset == preset
                                Button {
                                    cameraManager.setWhiteBalance(preset)
                                } label: {
                                    Text(preset.rawValue)
                                        .font(RetroTheme.monoLabel(10, weight: .semibold))
                                        .foregroundColor(active ? .black : .white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(active ? RetroTheme.amberAccent : RetroTheme.surface)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } else {
                    Text("LOCKED BY HARDWARE")
                        .font(RetroTheme.monoLabel(10))
                        .foregroundColor(RetroTheme.mutedText)
                }

                Spacer()

                Button {
                    cameraManager.resetAutoExposure()
                    cameraManager.resetAutoFocus()
                    cameraManager.setWhiteBalance(.auto)
                } label: {
                    Text("ALL AUTO")
                        .font(RetroTheme.monoLabel(10, weight: .semibold))
                        .foregroundColor(RetroTheme.amberAccent)
                }
            }
            .padding(.horizontal, 16)

            HStack(spacing: 14) {
                if cameraManager.capabilities.supportsManualISO {
                    TactileSlider(
                        label: cameraManager.isAutoExposure ? "ISO (AUTO)" : "ISO",
                        value: isoBinding,
                        range: Double(cameraManager.capabilities.minISO)...Double(cameraManager.capabilities.maxISO),
                        format: "%.0f"
                    )
                } else {
                    unsupportedReadout(title: "ISO", note: "N/A ON LENS")
                }

                if cameraManager.capabilities.supportsManualShutter {
                    VStack(spacing: 6) {
                        HStack {
                            Text(cameraManager.isAutoExposure ? "SHUTTER (AUTO)" : "SHUTTER")
                                .font(RetroTheme.monoLabel(10, weight: .medium))
                                .foregroundColor(RetroTheme.mutedText)
                            Spacer()
                            Text(ShutterSpeedFormatter.format(seconds: cameraManager.shutterSeconds))
                                .font(RetroTheme.monoLabel(11, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Slider(value: normalizedShutterBinding, in: 0...1)
                            .tint(RetroTheme.amberAccent)
                            .frame(height: 24)
                    }
                } else {
                    unsupportedReadout(title: "SHUTTER", note: "N/A ON LENS")
                }
            }
            .padding(.horizontal, 16)

            HStack(spacing: 12) {
                TactileSlider(
                    label: "EV COMP",
                    value: evBinding,
                    range: Double(cameraManager.capabilities.minExposureBias)...Double(cameraManager.capabilities.maxExposureBias),
                    format: "%+.1f"
                )

                if cameraManager.capabilities.supportsManualFocus {
                    TactileSlider(
                        label: cameraManager.isAutoFocus ? "FOCUS (AF)" : "FOCUS (MF)",
                        value: focusBinding,
                        range: 0...1,
                        format: "%.2f"
                    )
                } else {
                    unsupportedReadout(title: "FOCUS", note: "FIXED FOCUS")
                }

                TactileSlider(
                    label: "ZOOM",
                    value: zoomBinding,
                    range: Double(cameraManager.capabilities.minZoom)...Double(cameraManager.capabilities.maxZoom),
                    format: "%.1fx"
                )
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.88))
    }

    private func unsupportedReadout(title: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(RetroTheme.monoLabel(10))
                .foregroundColor(RetroTheme.mutedText)
            Text(note)
                .font(RetroTheme.monoLabel(10, weight: .semibold))
                .foregroundColor(RetroTheme.mutedText)
                .frame(height: 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
