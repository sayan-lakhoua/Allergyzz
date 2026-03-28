// Apple Developer Documentation used for AllergiesIntroductionView:
// https://developer.apple.com/documentation/swiftui/geometryreader
// https://developer.apple.com/documentation/swift/task/sleep(for:)

import SwiftUI

// Shows the different types of allergies
struct AllergiesIntroductionView: View {
    var onNext: () -> Void

    @Environment(SpeechManager.self) var speech
    @State private var isTapped = false

    let dialogueText = "Being allergic to something means your immune system mistakes something harmless for a dangerous threat. This can happen with food, pollen, insects or even medicines. These are called allergens. If you don't have an allergy to them, they're completely harmless."

    var body: some View {
        ZStack {
            BackgroundColorView()

            GeometryReader { g in
                VStack(spacing: 0) {
                    Spacer().frame(height: g.size.height * 0.08)
                    Image("allergiesAllergyzz")
                        .resizable()
                        .scaledToFill()
                        .frame(width: g.size.width, height: g.size.height * 0.85)
                        .clipped()
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
    AllergiesIntroductionView(onNext: {})
        .environment(AppSettings())
        .environment(SpeechManager())
}
