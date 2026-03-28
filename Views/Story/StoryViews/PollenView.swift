// Apple Developer Documentation used for PollenView:
// https://developer.apple.com/documentation/swiftui/appstorage
// https://developer.apple.com/documentation/swiftui/view/symboleffect(_:options:isactive:)

import SwiftUI

// Interactive page where the user taps the pollen grain, "triggering an allergic reaction"
struct PollenView: View {
    let onComplete: () -> Void
    @Binding var showHint: Bool
    var hintAutoDismiss: Bool
    
    @State var hasTapped = false
    @State var pollenFrame = 1
    @State private var showReaction = false
    @AppStorage("hintShown_pollenView") private var hintShown = false
    
    @Environment(SpeechManager.self) var speech
    @Environment(MusicManager.self) var musicManager
    
    let initialText = "Uh-oh... I'm not exactly sure what it is. To be safe, let's try to eliminate it as well."
    let completedText = "Oh no! This was just a pollen grain, it was completely harmless! When I overreact, it triggers an allergy."

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                BackgroundColorView()
                
                VStack {
                    Spacer()
                    
                    if hasTapped {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 180))
                            .symbolEffect(.wiggle, options: .repeating, isActive: true)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .yellow)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        PollenButton(pollenFrame: pollenFrame, screenWidth: geometry.size.width) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                hasTapped = true
                            }
                            if showHint { showHint = false }
                            musicManager.playSFX("incorrectAllergyzz")
                            speech.speak(completedText)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    DialogueBox(
                        text: hasTapped ? completedText : initialText,
                        expression: speech.isSpeaking ? .talking : (showReaction ? .disappointed : .scared),
                        isTalking: speech.isSpeaking,
                        showNextButton: hasTapped,
                        onNext: onComplete
                    )
                }
            }
        }
        .onAppear { speech.speak(initialText) }
        .onChange(of: speech.isSpeaking) { _, isSpeaking in
            if !isSpeaking && !hasTapped && !showHint {
                Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    guard !hasTapped, !showHint else { return }
                    withAnimation { showHint = true }
                }
            }
            if !isSpeaking && hasTapped {
                showReaction = true
            }
        }
        .onChange(of: hasTapped) { _, tapped in
            if tapped && showHint {
                withAnimation { showHint = false }
            }
        }
        .hintOverlay(gifName: "animationHandTapAllergyzz", isPresented: $showHint, autoDismiss: hintAutoDismiss)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(150))
                pollenFrame = pollenFrame % 6 + 1
            }
        }
    }
}

struct PollenButton: View {
    let pollenFrame: Int
    let screenWidth: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            Image("pollenState0\(pollenFrame)Allergyzz")
                .resizable()
                .scaledToFit()
                .frame(width: screenWidth * 0.45)
        }
        .accessibilityLabel("Pollen")
    }
}

#Preview {
    PollenView(onComplete: {}, showHint: .constant(false), hintAutoDismiss: true)
        .environment(AppSettings())
        .environment(SpeechManager())
}
