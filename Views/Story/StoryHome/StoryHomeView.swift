// Apple Developer Documentation used for StoryHomeView:
// https://developer.apple.com/documentation/swiftui/gesture
// https://developer.apple.com/documentation/avfaudio/avaudioplayer
// https://developer.apple.com/documentation/swiftui/view/fullscreencover(ispresented:ondismiss:content:)

import SwiftUI
import AVFoundation

// Home screen with the emergency kit and where the user has to drag the zip to start the story
struct StoryHomeView: View {

    @Environment(AppSettings.self) private var settings
    @Environment(MusicManager.self) private var musicManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var showStory = false
    @State private var showSettings = false
    @State private var showSpeedPicker = false
    @State private var showMuteOptions = false

    let totalFrames = 28

    @State private var currentFrame = 1
    @State private var isReadyToUnzip = false
    @State private var kitOpened = false

    @State private var lastDragPosition: CGPoint = .zero
    @State private var distanceTraveled: CGFloat = 0
    @State private var zipPlayer: AVAudioPlayer?

    var body: some View {
        GeometryReader { screen in
            let kitWidth = screen.size.width * 0.75

            ZStack {
                BackgroundColorView()
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    KitView(
                        kitWidth: kitWidth,
                        totalFrames: totalFrames,
                        currentFrame: $currentFrame,
                        isReadyToUnzip: isReadyToUnzip,
                        kitOpened: kitOpened,
                        lastDragPosition: $lastDragPosition,
                        distanceTraveled: $distanceTraveled,
                        onFinishUnzip: { finishUnzip() },
                        onResetZip: { resetZip() },
                        onStartDrag: { playZipSound() }
                    )

                    if !isReadyToUnzip && !kitOpened {
                        Button {
                            withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                                isReadyToUnzip = true
                            }
                        } label: {
                            Text("START")
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(height: 95)
                                .frame(width: 120)
                                .padding(.horizontal, 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(red: 0x32/255.0, green: 0x71/255.0, blue: 0xEA/255.0))
                                )
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }

                    if isReadyToUnzip && !kitOpened {
                        Text("Drag the zip to start the story")
                            .font(settings.font.font(.title3).weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                            .transition(.opacity)
                    }

                    Spacer()
                }

                HomeSettingsButtons(
                    colorScheme: colorScheme,
                    settings: settings,
                    musicManager: musicManager,
                    showSettings: $showSettings,
                    showMuteOptions: $showMuteOptions,
                    showSpeedPicker: $showSpeedPicker
                )
            }
            
        }
        .fullScreenCover(isPresented: $showStory, onDismiss: {
            // Reset home state so user can start again
            kitOpened = false
            isReadyToUnzip = false
            currentFrame = 1
            distanceTraveled = 0
        }) {
            StoryView()
                .withAppSettings()
                .preferredColorScheme(settings.appearance.colorScheme)
                .environment(settings)
                .environment(musicManager)
                .portraitOverlay()
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
                .withAppSettings()
                .preferredColorScheme(settings.appearance.colorScheme)
                .environment(settings)
                .portraitOverlay()
        }

    }

    private func finishUnzip() {
        let start = currentFrame
        Task {
            for i in 0...(totalFrames - start) {
                currentFrame = min(start + i, totalFrames)
                try? await Task.sleep(for: .milliseconds(30))
            }
            stopZipSound()
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                kitOpened = true
            }
            try? await Task.sleep(for: .milliseconds(250))
            showStory = true
        }
    }

    private func resetZip() {
        stopZipSound()
        distanceTraveled = 0
        currentFrame = 1
    }

    private func playZipSound() {
        guard zipPlayer == nil || zipPlayer?.isPlaying == false else { return }
        guard let url = Bundle.main.url(forResource: "zipSoundFX", withExtension: "m4a") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.play()
            zipPlayer = player
        } catch {
        }
    }

    private func stopZipSound() {
        zipPlayer?.stop()
        zipPlayer = nil
    }
}

// This handles the zip overlay on the Emergency Kit
struct KitView: View {
    let kitWidth: CGFloat
    let totalFrames: Int
    @Binding var currentFrame: Int
    let isReadyToUnzip: Bool
    let kitOpened: Bool
    @Binding var lastDragPosition: CGPoint
    @Binding var distanceTraveled: CGFloat
    let onFinishUnzip: () -> Void
    let onResetZip: () -> Void
    let onStartDrag: () -> Void

    private func zipFrameName(_ frame: Int) -> String {
        String(format: "emergencyKitZip%02dAllergyzz", frame)
    }

    var body: some View {
        // The full unzip needs roughly 1.5x the kit width of finger travel (this was a workaround as it was too complicated to make it turn to follow the Emergency Kit shape)
        let fullDistance = kitWidth * 1.5

        ZStack {
            Image("emergencyKitAllergyzz")
                .resizable()
                .scaledToFit()
                .frame(width: kitWidth)

            if !kitOpened {
                Image(zipFrameName(currentFrame))
                    .resizable()
                    .scaledToFit()
                    .frame(width: kitWidth)
                    .contentShape(Rectangle())
                    .gesture(
                        isReadyToUnzip
                        ? DragGesture(minimumDistance: 5)
                            .onChanged { value in
                                if distanceTraveled == 0 {
                                    onStartDrag()
                                }

                                let pos = CGPoint(
                                    x: value.translation.width,
                                    y: value.translation.height
                                )

                                let dx = pos.x - lastDragPosition.x
                                let dy = pos.y - lastDragPosition.y
                                let stepDistance = sqrt(dx * dx + dy * dy)

                                lastDragPosition = pos
                                distanceTraveled += stepDistance
                                let progress = min(distanceTraveled / fullDistance, 1)

                                let frame = 1 + Int(progress * CGFloat(totalFrames - 1))
                                currentFrame = max(1, min(totalFrames, frame))
                            }
                            .onEnded { _ in
                                lastDragPosition = .zero

                                if currentFrame >= 22 {
                                    onFinishUnzip()
                                } else {
                                    onResetZip()
                                }
                            }
                        : nil
                    )
            }
        }
    }
}

// The settings / mute / speed buttons in the top-right corner of the home screen
struct HomeSettingsButtons: View {
    let colorScheme: ColorScheme
    var settings: AppSettings
    var musicManager: MusicManager
    @Binding var showSettings: Bool
    @Binding var showMuteOptions: Bool
    @Binding var showSpeedPicker: Bool

    var body: some View {
        VStack {
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.body.weight(.semibold))
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .frame(width: 44, height: 44)
                            .background(colorScheme == .dark ? Color.black : Color.white)
                            .clipShape(.circle)
                    }
                    
                    Button {
                        showMuteOptions = true
                    } label: {
                        Image(systemName: settings.speechMuted && settings.musicMuted ? "speaker.slash.fill" : (settings.speechMuted || settings.musicMuted ? "speaker.wave.1.fill" : "speaker.wave.2.fill"))
                            .font(.body.weight(.semibold))
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .frame(width: 44, height: 44)
                            .background(colorScheme == .dark ? Color.black : Color.white)
                            .clipShape(.circle)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .popover(isPresented: $showMuteOptions, arrowEdge: .trailing) {
                        MutePopoverContent(settings: settings, musicManager: musicManager)
                    }
                    
                    Button {
                        showSpeedPicker = true
                    } label: {
                        Text(settings.speechSpeed.shortLabel)
                            .font(.system(.callout, design: .rounded, weight: .bold))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .frame(width: 44, height: 44)
                            .background(colorScheme == .dark ? Color.black : Color.white)
                            .clipShape(.circle)
                    }
                    .popover(isPresented: $showSpeedPicker, arrowEdge: .trailing) {
                        SpeedPopoverContent(settings: settings)
                    }
                }
                .padding(.trailing, 20)
                .padding(.top, 12)
            }
            Spacer()
        }
    }
}

// Popover for changing speech speed
struct SpeedPopoverContent: View {
    @Bindable var settings: AppSettings
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(SpeechSpeed.allCases) { speed in
                Button {
                    settings.speechSpeed = speed
                } label: {
                    HStack {
                        Text(speed.rawValue)
                        Spacer()
                        if settings.speechSpeed == speed {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                if speed != SpeechSpeed.allCases.last {
                    Divider()
                }
            }
        }
        .frame(width: 200)
        .presentationCompactAdaptation(.popover)
    }
}

// Popover for toggling speech and music on/off
struct MutePopoverContent: View {
    @Bindable var settings: AppSettings
    var musicManager: MusicManager
    
    var body: some View {
        VStack(spacing: 0) {
            Toggle(isOn: Binding(
                get: { !settings.speechMuted },
                set: { settings.speechMuted = !$0 }
            )) {
                Label("Speech", systemImage: "waveform")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            Toggle(isOn: Binding(
                get: { !settings.musicMuted },
                set: {
                    settings.musicMuted = !$0
                    if settings.musicMuted {
                        musicManager.pause()
                    } else {
                        musicManager.play()
                    }
                }
            )) {
                Label("Music", systemImage: "music.note")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 220)
        .presentationCompactAdaptation(.popover)
    }
}

#Preview {
    StoryHomeView()
        .environment(AppSettings())
}
