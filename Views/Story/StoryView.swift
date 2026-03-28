// Apple Developer Documentation used for StoryView:
// https://developer.apple.com/documentation/swiftui/appstorage
// https://developer.apple.com/documentation/swiftui/view/fullscreencover(ispresented:ondismiss:content:)
// https://developer.apple.com/documentation/swiftui/view/popover(ispresented:arrowedge:content:)

import SwiftUI

// StoryView manages page navigation, speech, settings, and hint overlays. (Template)
struct StoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppSettings.self) private var settings
    @Environment(MusicManager.self) private var musicManager

    @State private var currentPage = 0
    @State private var speech = SpeechManager()
    
    @State private var showSettings = false
    @State private var showSpeedPicker = false
    @State private var showMuteOptions = false

    @State private var showHint = false
    // When true, the hint is triggered by the ? button and stays until dismissed manually
    @State private var hintTriggeredByButton = false
    @State private var showHintPopover = false

    // Track which pages have already shown their auto-hint
    @AppStorage("hintShown_virusView") private var virusHintShown = false
    @AppStorage("hintShown_pollenView") private var pollenHintShown = false
    @AppStorage("hintShown_callESView") private var callESHintShown = false
    @AppStorage("hintShown_eaiCapStepsView") private var eaiCapHintShown = false
    @AppStorage("hintShown_eaiInjectionView") private var eaiInjectionHintShown = false

    let totalPages = 21

    // Custom binding that marks the hint as "shown" when it's dismissed
    private var showHintBinding: Binding<Bool> {
        Binding(
            get: { showHint },
            set: { newValue in
                if showHint && !newValue {
                    switch currentPage {
                    case 5: virusHintShown = true
                    case 6: pollenHintShown = true
                    case 14: callESHintShown = true
                    case 16: eaiCapHintShown = true
                    case 17: eaiInjectionHintShown = true
                    default: break
                    }
                    hintTriggeredByButton = false
                }
                showHint = newValue
            }
        )
    }

    // Only show the ? button after the auto-hint has played once
    private var shouldShowHintButton: Bool {
        switch currentPage {
        case 5: return virusHintShown
        case 6: return pollenHintShown
        case 14: return callESHintShown
        case 16: return eaiCapHintShown
        case 17: return eaiInjectionHintShown
        default: return false
        }
    }

    private var hintAutoDismiss: Bool {
        !hintTriggeredByButton
    }

    private var hintText: String {
        switch currentPage {
        case 5: return "Tap on the virus to eliminate it"
        case 6: return "Tap on the pollen grain to eliminate it"
        case 14: return "Hold both side buttons to activate Emergency SOS"
        case 16: return "Drag the slider to remove the blue safety cap"
        case 17: return "Press and hold to complete the injection"
        default: return ""
        }
    }

    // Buttons to go to the previous page, settings, mute (sound settings), speech speed and hint
    var body: some View {
        ZStack {
            pageContent(for: currentPage)
                .id(currentPage)
                .transition(.opacity)
                .environment(speech)
                .environment(settings)

            VStack {
                HStack(alignment: .top) {
                    if currentPage > 0 {
                        Button { previousPage() } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .symbolRenderingMode(.monochrome)
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .frame(width: 44, height: 44)
                                .background(colorScheme == .dark ? Color.black : Color.white)
                                .clipShape(.circle)
                        }
                        .accessibilityLabel("Back")
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                                .font(.body.weight(.semibold))
                                .symbolRenderingMode(.monochrome)
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .frame(width: 44, height: 44)
                                .background(colorScheme == .dark ? Color.black : Color.white)
                                .clipShape(.circle)
                        }
                        .accessibilityLabel("Settings")
                        
                        Button { showMuteOptions = true } label: {
                            Image(systemName: settings.speechMuted && settings.musicMuted ? "speaker.slash.fill" : (settings.speechMuted || settings.musicMuted ? "speaker.wave.1.fill" : "speaker.wave.2.fill"))
                                .font(.body.weight(.semibold))
                                .symbolRenderingMode(.monochrome)
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .frame(width: 44, height: 44)
                                .background(colorScheme == .dark ? Color.black : Color.white)
                                .clipShape(.circle)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .accessibilityLabel("Sound Options")
                        .popover(isPresented: $showMuteOptions, arrowEdge: .trailing) {
                            MutePopoverContent(settings: settings, musicManager: musicManager)
                        }
                        
                        Button { showSpeedPicker = true } label: {
                            Text(settings.speechSpeed.shortLabel)
                                .font(.system(.callout, design: .rounded, weight: .bold))
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .frame(width: 44, height: 44)
                                .background(colorScheme == .dark ? Color.black : Color.white)
                                .clipShape(.circle)
                        }
                        .accessibilityLabel("Speech Speed")
                        .popover(isPresented: $showSpeedPicker, arrowEdge: .trailing) {
                            SpeedPopoverContent(settings: settings)
                        }
                        
                        if shouldShowHintButton {
                            Button {
                                showHintPopover = true
                                if !showHint {
                                    hintTriggeredByButton = true
                                    withAnimation { showHintBinding.wrappedValue = true }
                                }
                            } label: {
                                Image(systemName: "questionmark")
                                    .font(.body.weight(.semibold))
                                    .symbolRenderingMode(.monochrome)
                                    .foregroundStyle(.black)
                                    .frame(width: 44, height: 44)
                                    .background(Color.yellow)
                                    .clipShape(.circle)
                            }
                            .accessibilityLabel("Show Hint")
                            .transition(.scale.combined(with: .opacity))
                            .popover(isPresented: $showHintPopover, arrowEdge: .trailing) {
                                Text(hintText)
                                    .font(.system(.body, design: .rounded, weight: .medium))
                                    .padding(16)
                                    .presentationCompactAdaptation(.popover)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                Spacer()
            }
        }
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
                .withAppSettings()
                .preferredColorScheme(settings.appearance.colorScheme)
                .environment(settings)
                .portraitOverlay()
        }
        .onAppear {
            speech.speakingRate = settings.speechSpeed.utteranceRate
            speech.isMuted = settings.speechMuted
            preloadHintGIFs()
        }
        .onChange(of: settings.speechSpeed) { _, speed in
            speech.speakingRate = speed.utteranceRate
        }
        .onChange(of: settings.speechMuted) { _, muted in
            speech.isMuted = muted
        }
    }

    // Maps each page number to its view
    @ViewBuilder
    func pageContent(for page: Int) -> some View {
        switch page {
        case 0: ImmuneCellIntroView(onNext: nextPage)
        case 1: AllergiesIntroductionView(onNext: nextPage)
        case 2: AllergiesOrderView(onNext: nextPage)
        case 3: ETBView(onNext: nextPage)
        case 4: ISCharacterView(onNext: nextPage)
        case 5: VirusView(onComplete: nextPage, showHint: showHintBinding, hintAutoDismiss: hintAutoDismiss)
        case 6: PollenView(onComplete: nextPage, showHint: showHintBinding, hintAutoDismiss: hintAutoDismiss)
        case 7: AllergicReaction(onNext: nextPage)
        case 8: HistamineFormulaView(onNext: nextPage)
        case 9: AntihistamineView(onNext: nextPage)
        case 10: CharacterProtectView(onNext: nextPage)
        case 11: AnaphylacticAlertView(onNext: nextPage)
        case 12: AnaphylacticExplanationView(onNext: nextPage)
        case 13: EmergencyStepsView(onNext: nextPage)
        case 14: CallESView(onComplete: nextPage, showHint: showHintBinding, hintAutoDismiss: hintAutoDismiss)
        case 15: EAIView(onNext: nextPage)
        case 16: EAICapStepsView(onComplete: nextPage, showHint: showHintBinding, hintAutoDismiss: hintAutoDismiss)
        case 17: EAIInjectionView(onComplete: nextPage, showHint: showHintBinding, hintAutoDismiss: hintAutoDismiss)
        case 18: AmbulanceView(onNext: nextPage)
        case 19: AllergiesStatsView(onNext: nextPage)
        case 20: NotAloneView(onNext: { speech.stop(); dismiss() })
        default: EmptyView()
        }
    }

    func nextPage() {
        speech.stop()
        showHint = false
        hintTriggeredByButton = false
        showHintPopover = false
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage += 1
        }
    }
    
    func previousPage() {
        guard currentPage > 0 else { return }
        speech.stop()
        showHint = false
        hintTriggeredByButton = false
        showHintPopover = false
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage -= 1
        }
    }
}

#Preview {
    StoryView()
        .environment(AppSettings())
}
