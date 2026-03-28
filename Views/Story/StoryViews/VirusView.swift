// Apple Developer Documentation used for VirusView:
// https://developer.apple.com/documentation/swiftui/appstorage
// https://developer.apple.com/documentation/swiftui/view/symboleffect(_:options:isactive:)

import SwiftUI

// Interactive page where the user taps the virus to eliminate it
struct VirusView: View {
    var onComplete: () -> Void
    @Binding var showHint: Bool
    var hintAutoDismiss: Bool
    
    @State private var gotIt = false
    @State private var frame = 1
    @State private var showReaction = false
    @AppStorage("hintShown_virusView") private var hintShown = false
    @Environment(SpeechManager.self) var speech
    @Environment(MusicManager.self) var musicManager
    
    let initialText = "Oh no! A virus! Let's eliminate it!"
    let completedText = "Great! We removed a threat!"

    var body: some View {
        GeometryReader { geo in
            ZStack {
                BackgroundColorView()
                
                VStack {
                    Spacer()
                    
                    if !gotIt {
                        VirusButton(frame: frame, width: geo.size.width) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                gotIt = true
                            }
                            if showHint { showHint = false }
                            musicManager.playSFX("correctAllergyzz")
                            speech.speak(completedText)
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 180))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .green)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    DialogueBox(
                        text: gotIt ? completedText : initialText,
                        expression: speech.isSpeaking ? .talking : (showReaction ? .happy : .stressed),
                        isTalking: speech.isSpeaking,
                        showNextButton: gotIt,
                        onNext: onComplete
                    )
                }
            }
        }
        .onAppear { speech.speak(initialText) }
        .onChange(of: speech.isSpeaking) { _, isSpeaking in
            // Show the hint after speech finishes if the virus hasn't been tapped
            if !isSpeaking && !gotIt && !showHint {
                Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    guard !gotIt, !showHint else { return }
                    withAnimation { showHint = true }
                }
            }
            if !isSpeaking && gotIt {
                showReaction = true
            }
        }
        .onChange(of: gotIt) { _, done in
            if done && showHint {
                withAnimation { showHint = false }
            }
        }
        .hintOverlay(gifName: "animationHandTapAllergyzz", isPresented: $showHint, autoDismiss: hintAutoDismiss)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(150))
                frame = frame % 6 + 1
            }
        }
    }
}

struct VirusButton: View {
    let frame: Int
    let width: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            Image("virusState0\(frame)Allergyzz")
                .resizable()
                .scaledToFit()
                .frame(width: width * 0.45)
        }
        .accessibilityLabel("Virus")
    }
}

#Preview {
    VirusView(onComplete: {}, showHint: .constant(false), hintAutoDismiss: true)
        .environment(AppSettings())
        .environment(SpeechManager())
}
