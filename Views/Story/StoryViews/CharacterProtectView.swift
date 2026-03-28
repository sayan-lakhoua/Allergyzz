// Apple Developer Documentation used for CharacterProtectView:
// https://developer.apple.com/documentation/swiftui/view/task(priority:_:)
// https://developer.apple.com/documentation/swift/task/sleep(for:)

import SwiftUI

// Animated scene showing the character avoiding allergens (protect)
struct CharacterProtectView: View {
    var onNext: () -> Void

    @Environment(SpeechManager.self) var speech
    
    @State private var currentImageIndex = 0
    
    let characterImages = [
        "characterProtect00Allergyzz",
        "characterProtect01Allergyzz",
        "characterProtect02Allergyzz",
        "characterProtect03Allergyzz",
        "characterProtect04Allergyzz",
        "characterProtect05Allergyzz",
        "characterProtect06Allergyzz"
    ]

    let dialogueText = "People with allergies need to be careful and make sure they stay away from their allergens."

    var body: some View {
        ZStack {
            BackgroundColorView()

            GeometryReader { g in
                Image(characterImages[currentImageIndex])
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height * 0.92, alignment: .bottom)
                    .clipped()
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .ignoresSafeArea()
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(200))
                    currentImageIndex = (currentImageIndex + 1) % characterImages.count
                }
            }

            VStack {
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
        .onAppear { speech.speak(dialogueText) }
    }
}

#Preview {
    CharacterProtectView(onNext: {})
        .environment(AppSettings())
        .environment(SpeechManager())
}
