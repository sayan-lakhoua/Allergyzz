// Apple Developer Documentation used for ETBView:
// https://developer.apple.com/documentation/swiftui/hstack
// https://developer.apple.com/documentation/swift/task/sleep(for:)

import SwiftUI

// Shows Eat, Touch, Breathe cards
struct ETBView: View {
    var onNext: () -> Void

    @Environment(SpeechManager.self) var speech

    let dialogueText = "You can be allergic to anything you can eat, touch or breathe in."

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                BackgroundColorView()

                HStack(spacing: 20) {
                    AllergyCard(
                        imageName: "characterAllergyEatAllergyzz",
                        title: "Eat",
                        color: Color(red: 0.95, green: 0.45, blue: 0.45)
                    )

                    AllergyCard(
                        imageName: "characterAllergyTouchAllergyzz",
                        title: "Touch",
                        color: Color(red: 0.55, green: 0.75, blue: 0.95)
                    )

                    AllergyCard(
                        imageName: "characterAllergyBreatheAllergyzz",
                        title: "Breathe",
                        color: Color(red: 0.65, green: 0.85, blue: 0.55)
                    )
                }
                .frame(height: min(geometry.size.height * 0.65, 350))
                .padding(.horizontal, 24)

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

// Card
struct AllergyCard: View {
    let imageName: String
    let title: String
    let color: Color

    @Environment(\.colorScheme) var colorScheme
    @State private var isAnimating = false
    @State private var isTapped = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width * 1.4)
                        .frame(width: geometry.size.width, alignment: .center)
                }

                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.top, 12)
                    .padding(.leading, 12)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
        .clipShape(.rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .scaleEffect(isAnimating ? 1.0 : 0.8)
        .opacity(isAnimating ? 1.0 : 0)
        .scaleEffect(isTapped ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.4), value: isTapped)
        .onTapGesture {
            isTapped = true
            Task {
                try? await Task.sleep(for: .milliseconds(150))
                isTapped = false
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double.random(in: 0...0.3))) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    ETBView(onNext: {})
        .environment(AppSettings())
        .environment(SpeechManager())
}
