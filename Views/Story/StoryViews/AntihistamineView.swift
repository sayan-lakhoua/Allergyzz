// Apple Developer Documentation used for AntihistamineView:
// https://developer.apple.com/documentation/swiftui/geometryreader

import SwiftUI

// Shows antihistamine medicine illustrations and explains what they do
struct AntihistamineView: View {
    var onNext: () -> Void

    @Environment(SpeechManager.self) var speech

    let dialogueText = "Allergic people usually have antihistamines with them. These medicines cancel out the histamine."

    var body: some View {
        GeometryReader { geometry in
            let isPortrait = geometry.size.height > geometry.size.width
            ZStack {
                BackgroundColorView()

                ZStack {
                    Image("medicineBoxAllergyzz")
                        .resizable()
                        .scaledToFit()
                        .frame(height: geometry.size.height * (isPortrait ? 0.35 : 0.55))
                        .offset(x: isPortrait ? -30 : -60, y: -20)
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 5, y: 5)

                    Image("medicineOralSolutionAllergyzz")
                        .resizable()
                        .scaledToFit()
                        .frame(height: geometry.size.height * (isPortrait ? 0.28 : 0.45))
                        .offset(x: isPortrait ? 60 : 120, y: 30)
                        .shadow(color: .black.opacity(0.2), radius: 12, x: 8, y: 8)
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
        }
        .onAppear { speech.speak(dialogueText) }
    }
}

#Preview {
    AntihistamineView(onNext: {})
        .environment(AppSettings())
        .environment(SpeechManager())
}
