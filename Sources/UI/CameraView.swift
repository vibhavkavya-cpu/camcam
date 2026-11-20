import AVFoundation
import SwiftUI

struct CameraView: View {
    @EnvironmentObject private var appState: AppState
    @State private var shutterFlashOpacity: Double = 0.0
    @State private var focusHideTask: DispatchWorkItem?

    var body: some View {
        ZStack {
            RetroTheme.background.ignoresSafeArea()

            if appState.cameraManager.permissionState == .denied {
                permissionDeniedView
            } else {
                VStack(spacing: 0) {
                    topBar

                    ZStack {
                        CameraPreview(
                            cameraManager: appState.cameraManager,
                            onTap: { viewPoint, devicePoint in
                                appState.cameraManager.tapToFocus(viewPoint: viewPoint, devicePoint: devicePoint)
                                scheduleFocusReticleHide()
                            },
                            onPinch: { delta in
                                let nextZoom = appState.cameraManager.zoomFactor * delta
                                appState.cameraManager.setZoom(nextZoom)
                            }
                        )
                        .gesture(
                            DragGesture(minimumDistance: 28)
                                .onEnded { value in
                                    if abs(value.translation.width) > abs(value.translation.height) {
                                        cyclePreset(direction: value.translation.width < 0 ? 1 : -1)
                                    }
                                }
                        )

                        if let point = appState.cameraManager.focusIndicatorPoint {
                            FocusReticleView(
                                point: point,
                                exposureBias: $appState.cameraManager.exposureBias,
                                minBias: appState.cameraManager.capabilities.minExposureBias,
                                maxBias: appState.cameraManager.capabilities.maxExposureBias,
                                onBiasChanged: { newBias in
                                    appState.cameraManager.setExposureBias(newBias)
                                    scheduleFocusReticleHide()
                                }
                            )
                        }

                        Color.black
                            .opacity(shutterFlashOpacity)
                            .allowsHitTesting(false)

                        VStack {
                            Spacer()
                            HStack(spacing: 10) {
                                Text(appState.filterLibrary.currentPreset.name.uppercased())
                                    .foregroundColor(RetroTheme.amberAccent)
                                Text("ISO \(Int(round(appState.cameraManager.liveISO)))")
                                Text(ShutterSpeedFormatter.format(seconds: appState.cameraManager.liveShutterSeconds))
                                if appState.cameraManager.zoomFactor > 1.05 {
                                    Text(String(format: "%.1fx", appState.cameraManager.zoomFactor))
                                }
                            }
                            .font(RetroTheme.monoLabel(10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.55))
                            .padding(.bottom, 10)
                        }
                        .allowsHitTesting(false)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                    if appState.activeMode == .filters {
                        FilterSelector(
                            filterLibrary: appState.filterLibrary,
                            onFilterChanged: { preset in
                                appState.cameraManager.syncFilterState(
                                    parameters: preset.parameters,
                                    presetName: preset.name
                                )
                            },
                            onOpenEditor: {
                                appState.isEditorPresented = true
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if appState.activeMode == .manual {
                        ManualControlsView(cameraManager: appState.cameraManager)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    bottomControlDeck
                }
            }
        }
        .onAppear {
            appState.cameraManager.checkPermissionsAndStart()
            appState.cameraManager.syncFilterState(
                parameters: appState.filterLibrary.activeParameters,
                presetName: appState.filterLibrary.currentPreset.name
            )
        }
        .onChange(of: appState.filterLibrary.activeParameters) { _, newParams in
            appState.cameraManager.syncFilterState(
                parameters: newParams,
                presetName: appState.filterLibrary.currentPreset.name
            )
        }
        .fullScreenCover(isPresented: $appState.isGalleryPresented) {
            GalleryView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.isEditorPresented) {
            FilterEditorView(initialParameters: appState.filterLibrary.activeParameters)
                .environmentObject(appState)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                appState.cameraManager.cycleFlashMode()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: flashIconName)
                        .font(.system(size: 16, weight: .medium))
                    Text(flashLabel)
                        .font(RetroTheme.monoLabel(10, weight: .semibold))
                }
                .foregroundColor(appState.cameraManager.flashMode == .on ? RetroTheme.amberAccent : .white)
                .opacity(appState.cameraManager.capabilities.supportsFlash ? 1.0 : 0.35)
                .frame(minWidth: 56, alignment: .leading)
            }
            .disabled(!appState.cameraManager.capabilities.supportsFlash)

            Spacer()

            Button {
                appState.cameraManager.isLiveMotionEnabled.toggle()
            } label: {
                HStack(spacing: 5) {
                    Circle()
                        .fill(appState.cameraManager.isLiveMotionEnabled ? RetroTheme.amberAccent : RetroTheme.mutedText)
                        .frame(width: 6, height: 6)
                    Text(appState.cameraManager.isLiveMotionEnabled ? "RAW+LIVE" : "ZERO-HDR")
                        .font(RetroTheme.monoLabel(10, weight: .semibold))
                        .foregroundColor(appState.cameraManager.isLiveMotionEnabled ? RetroTheme.amberAccent : .white.opacity(0.75))
                }
            }

            Spacer()

            Button {
                appState.cameraManager.switchCamera()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .frame(minWidth: 56, alignment: .trailing)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color.black)
    }

    private var bottomControlDeck: some View {
        VStack(spacing: 14) {
            HStack {
                Button {
                    appState.isGalleryPresented = true
                } label: {
                    if let thumb = appState.libraryManager.latestThumbnail {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 46, height: 46)
                            .clipped()
                            .overlay(Rectangle().stroke(Color.white.opacity(0.35), lineWidth: 1))
                    } else {
                        Rectangle()
                            .fill(RetroTheme.surface)
                            .frame(width: 46, height: 46)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 16))
                                    .foregroundColor(RetroTheme.mutedText)
                            )
                            .overlay(Rectangle().stroke(RetroTheme.hairline, lineWidth: 1))
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                ShutterButton(isCapturing: appState.cameraManager.isCapturing) {
                    triggerShutterAnimation()
                    appState.cameraManager.capturePhoto()
                }

                Spacer()

                Button {
                    appState.isEditorPresented = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 46, height: 46)
                        .background(RetroTheme.surface)
                        .overlay(Rectangle().stroke(RetroTheme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)

            HStack(spacing: 28) {
                ForEach(CameraMode.allCases) { mode in
                    let isSelected = appState.activeMode == mode
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            appState.activeMode = mode
                        }
                    } label: {
                        Text(mode.rawValue)
                            .font(RetroTheme.monoLabel(12, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? RetroTheme.amberAccent : RetroTheme.mutedText)
                            .tracking(1.1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 10)
        }
        .padding(.top, 12)
        .background(Color.black)
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.fill")
                .font(.system(size: 32))
                .foregroundColor(RetroTheme.amberAccent)
            Text("CAMERA ACCESS REQUIRED")
                .font(RetroTheme.monoLabel(13, weight: .bold))
                .foregroundColor(.white)
            Text("Enable camera access in iOS Settings to use Digicam.")
                .font(RetroTheme.uiLabel(13))
                .foregroundColor(RetroTheme.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("OPEN SETTINGS") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(RetroTheme.monoLabel(12, weight: .bold))
            .foregroundColor(.black)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(RetroTheme.amberAccent)
        }
    }

    private var flashIconName: String {
        switch appState.cameraManager.flashMode {
        case .on:   return "bolt.fill"
        case .auto: return "bolt.badge.a.fill"
        case .off:  return "bolt.slash.fill"
        @unknown default: return "bolt.slash.fill"
        }
    }

    private var flashLabel: String {
        switch appState.cameraManager.flashMode {
        case .on:   return "ON"
        case .auto: return "AUTO"
        case .off:  return "OFF"
        @unknown default: return "OFF"
        }
    }

    private func triggerShutterAnimation() {
        withAnimation(.easeOut(duration: 0.06)) {
            shutterFlashOpacity = 0.85
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeIn(duration: 0.14)) {
                shutterFlashOpacity = 0.0
            }
        }
    }

    private func scheduleFocusReticleHide() {
        focusHideTask?.cancel()
        let task = DispatchWorkItem {
            withAnimation(.easeOut(duration: 0.25)) {
                appState.cameraManager.focusIndicatorPoint = nil
            }
        }
        focusHideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: task)
    }

    private func cyclePreset(direction: Int) {
        let all = appState.filterLibrary.presets
        guard let currentIndex = all.firstIndex(where: { $0.id == appState.filterLibrary.selectedPresetID }) else { return }
        let nextIndex = (currentIndex + direction + all.count) % all.count
        let next = all[nextIndex]
        appState.filterLibrary.selectPreset(next)
        appState.cameraManager.syncFilterState(parameters: next.parameters, presetName: next.name)
    }
}
