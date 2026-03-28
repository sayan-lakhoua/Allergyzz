// Apple Developer Documentation used for ISCharacterView:
// https://developer.apple.com/documentation/swiftui/geometryreader
// https://developer.apple.com/documentation/swift/task/sleep(for:)

import SwiftUI

// Shows the full character illustration and explains what the immune system does
struct ISCharacterView: View {
    var onNext: () -> Void
    
    @Environment(SpeechManager.self) var speech
    @State private var isTapped = false
    
    let dialogueText = "As an immune cell, I'm part of your immune system. That's the part of your body that protects you against viruses and diseases."

    var body: some View {
        ZStack {
            BackgroundColorView()
            
            GeometryReader { g in
                Image("characterNeutralAllergyzz")
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height * 0.92, alignment: .bottom)
                    .clipped()
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .scaleEffect(isTapped ? 0.97 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.4), value: isTapped)
                    .onTapGesture {
                        isTapped = true
                        Task {
                            try? await Task.sleep(for: .milliseconds(150))
                            isTapped = false
                        }
                    }
            }
            .ignoresSafeArea()
            
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
    ISCharacterView(onNext: {})
        .environment(AppSettings())
        .environment(SpeechManager())
}
