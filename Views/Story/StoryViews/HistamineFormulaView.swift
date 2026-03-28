// Apple Developer Documentation used for HistamineFormulaView:
// https://developer.apple.com/documentation/swiftui/geometryreader

import SwiftUI

// Shows the histamine chemical formula
struct HistamineFormulaView: View {
    var onNext: () -> Void
    
    @Environment(SpeechManager.self) var speech
    
    let dialogueText = "This chemical is called histamine. It can make you sneeze, cough, give you a runny nose or a rash."

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                BackgroundColorView()
                
                VStack {
                    Spacer()
                    Image("formulaHistamineAllergyzz")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width * 0.8)
                    
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
    }
}

#Preview {
    HistamineFormulaView(onNext: {})
        .environment(AppSettings())
        .environment(SpeechManager())
}
