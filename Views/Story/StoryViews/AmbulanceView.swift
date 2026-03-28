// Apple Developer Documentation used for AmbulanceView:
// https://developer.apple.com/documentation/swiftui/geometryreader

import SwiftUI

// Shows the ambulance illustration after the injection step
struct AmbulanceView: View {
    var onNext: () -> Void

    @Environment(SpeechManager.self) var speech

    let dialogueText = "After the injection, the person having the anaphylactic reaction needs to go to the hospital quickly!"

    var body: some View {
        ZStack {
            BackgroundColorView()

            GeometryReader { g in
                Image("ambulanceAllergyzz")
                    .resizable()
                    .scaledToFit()
                    .frame(width: g.size.width * 0.8)
                    .frame(width: g.size.width)
                    .offset(y: g.size.height * 0.15)
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
    AmbulanceView(onNext: {})
        .environment(AppSettings())
        .environment(SpeechManager())
}
