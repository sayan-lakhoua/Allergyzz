// Apple Developer Documentation used for AllergicReaction:
// https://developer.apple.com/documentation/swiftui/view/task(priority:_:)
// https://developer.apple.com/documentation/swift/task/sleep(for:)

import SwiftUI

// Shows the mast cell animation and explains how allergic reactions start
struct AllergicReaction: View {
    var onNext: () -> Void
    
    @Environment(SpeechManager.self) var speech
    
    let dialogueText = "When I get confused like I just did, I alert special cells called Mast cells. To help me fight against the misidentified threat, they produce a chemical..."
    
    @State private var currentFrame = 1
    let frameDelay = 200

    var body: some View {
        GeometryReader { geo in
            ZStack {
                BackgroundColorView()
                
                VStack {
                    Spacer()
                    
                    MastCellImage(currentFrame: currentFrame, size: geo.size)
                    
                    Spacer()
                    
                    DialogueBox(
                        text: dialogueText,
                        expression: .talking,
                        isTalking: speech.isSpeaking,
                        showNextButton: true,
                        onNext: onNext
                    )
                }
            }
        }
        .onAppear { speech.speak(dialogueText) }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(frameDelay))
                currentFrame = currentFrame % 6 + 1
            }
        }
    }
}

// Animated Mast Cell
struct MastCellImage: View {
    let currentFrame: Int
    let size: CGSize
    
    var body: some View {
        Image("mastCellState0\(currentFrame)Allergyzz")
            .resizable()
            .scaledToFit()
            .frame(width: size.width * 0.45)
    }
}

#Preview {
    AllergicReaction(onNext: {})
        .environment(AppSettings())
        .environment(SpeechManager())
}
