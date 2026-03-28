// Apple Developer Documentation used for AnaphylacticAlertView:
// https://developer.apple.com/documentation/swiftui/animation/repeatforever(autoreverses:)
// https://developer.apple.com/documentation/swiftui/view/onchange(of:_:)

import SwiftUI

// Shows anaphylaxis girl with the flashing red
struct AnaphylacticAlertView: View {
    var onNext: () -> Void
    
    @Environment(SpeechManager.self) private var speech
    @State private var isFlashing = false
    @State private var showReaction = false
    
    let dialogueText = "A really big allergic reaction is called anaphylaxis. This happens when the body produces so much histamine that it can stop you from being able to breathe. This can be extremely dangerous."
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                BackgroundColorView()
                
                Image("characterAnaphylacticReactionAllergyzz")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.92, alignment: .bottom)
                    .clipped()
                    .frame(maxHeight: .infinity, alignment: .bottom)
                
                // Red overlay that pulses to create urgency
                Color.red
                    .opacity(isFlashing ? 0.3 : 0.1)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isFlashing)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    DialogueBox(
                        text: dialogueText,
                        expression: speech.isSpeaking ? .talking : (showReaction ? .scared : .talking),
                        isTalking: speech.isSpeaking,
                        showNextButton: true,
                        onNext: onNext
                    )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            isFlashing = true
            speech.speak(dialogueText)
        }
        .onChange(of: speech.isSpeaking) { _, isSpeaking in
            if !isSpeaking {
                showReaction = true
            }
        }
    }
}

#Preview {
    AnaphylacticAlertView(onNext: {})
        .environment(AppSettings())
        .environment(SpeechManager())
}
