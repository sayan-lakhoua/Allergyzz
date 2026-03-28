// Apple Developer Documentation used for ImmuneCellIntroView:
// https://developer.apple.com/documentation/swiftui/geometryreader

import SwiftUI

// First page of the story where Clearus introduces himself
struct ImmuneCellIntroView: View {
    var onNext: () -> Void
    
    @Environment(SpeechManager.self) var speech
    
    let dialogueText = "Hello, I'm Clearus, one of your immune cells. I'm here to talk to you about allergies."
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                BackgroundColorView()
                
                VStack {
                    Spacer()
                    
                    ImmuneCellAnimatedView(
                        expression: .talking,
                        size: geo.size.width * 0.45,
                        isTalking: speech.isSpeaking
                    )
                    
                    Spacer()
                    
                    DialogueBox(
                        text: dialogueText,
                        expression: .talking,
                        isTalking: speech.isSpeaking,
                        showCharacter: false,
                        showNextButton: true,
                        onNext: onNext
                    )
                }
            }
        }
        .onAppear { speech.speak(dialogueText) }
    }
}

#Preview {
    ImmuneCellIntroView(onNext: {})
        .environment(AppSettings())
        .environment(SpeechManager())
}
