// Apple Developer Documentation used for AllergiesStatsView:
// https://developer.apple.com/documentation/swiftui/view/ongeometrychange(for:of:action:)
// https://developer.apple.com/documentation/swiftui/animation/logicallycomplete(after:)

import SwiftUI

struct AllergyStat: Identifiable {
    let id: Int
    let before: String
    let image: String
    let after: String
}

let allergyStats: [AllergyStat] = [
    AllergyStat(
        id: 0,
        before: "",
        image: "over35Allergyzz",
        after: "35%+ of people are affected by allergies worldwide"
    ),
    AllergyStat(
        id: 1,
        before: "",
        image: "1-3Allergyzz",
        after: "1/3 of Americans are affected by allergies, that's over 100 million people"
    ),
    AllergyStat(
        id: 2,
        before: "",
        image: "10sAllergyzz",
        after: "Every 10s a food allergy reaction sends someone to the ER."
    ),
    AllergyStat(
        id: 3,
        before: "",
        image: "economicImpactAllergyzz",
        after: "Food allergies cost the US economy over $24.8B annually"
    ),
    AllergyStat(
        id: 4,
        before: "",
        image: "2xAllergyzz",
        after: "The number of people with food allergies has doubled in less than 20 years."
    ),
    AllergyStat(
        id: 5,
        before: "",
        image: "over70Allergyzz",
        after: "Epinephrine Auto-Injector prescriptions grew by 70%+ in less than 10 years."
    ),
    AllergyStat(
        id: 6,
        before: "",
        image: "80PercentAllergyzz",
        after: "80% of people with an Epinephrine Auto-Injector don't know how to use it correctly."
    ),
    AllergyStat(
        id: 7,
        before: "",
        image: "over50Allergyzz",
        after: "50%+ of Epinephrine Auto-Injectors are used incorrectly during an emergency."
    )
]

// Shows allergy statistics as a swipeable card stack
struct AllergiesStatsView: View {
    var onNext: () -> Void

    @Environment(AppSettings.self) var settings
    @Environment(SpeechManager.self) var speech

    let dialogueText = "Allergies affect millions of people around the world. Knowledge is the first step to saving lives!"

    var body: some View {
        ZStack {
            BackgroundColorView()

            VStack(spacing: 0) {
                Spacer()

                StatCardStack()

                Spacer()

                DialogueBox(
                    text: dialogueText,
                    expression: .happy,
                    isTalking: speech.isSpeaking,
                    showNextButton: true,
                    onNext: onNext
                )
            }
        }
        .onAppear {
            speech.speak(dialogueText)
        }
    }
}

// Looping card stack
struct StatCardStack: View {
    @State private var rotation: Int = 0
    
    @Environment(\.colorScheme) var colorScheme
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(.systemGray5) : .white
    }
    
    var body: some View {
        GeometryReader { geo in
            let isPortrait = geo.size.height > geo.size.width
            let cardWidth: CGFloat = isPortrait
                ? min(geo.size.width * 0.75, 340)
                : min(geo.size.width * 0.50, 500)
            let cardHeight: CGFloat = isPortrait
                ? cardWidth * 1.3
                : min(geo.size.height * 0.85, 420)
            
            let rotated = allergyStats.rotateFromLeft(by: rotation)
            let count = rotated.count
            
            ZStack {
                ForEach(rotated) { stat in
                    let index = rotated.firstIndex(where: { $0.id == stat.id }) ?? 0
                    let zIndex = Double(count - index)
                    let item = rotated[index]
                    
                    StatCardContent(stat: item, cardBackground: cardBackground)
                        .frame(width: cardWidth, height: cardHeight)
                        .clipShape(.rect(cornerRadius: 24))
                        .shadow(color: .black.opacity(index == 0 ? 0.15 : 0.08), radius: 10, y: 4)
                        .modifier(StatCardModifier(
                            index: index,
                            count: count,
                            visibleCardsCount: 3,
                            rotation: $rotation
                        ))
                        .zIndex(zIndex)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .padding()
    }
}

private struct StatCardModifier: ViewModifier {
    var index: Int
    var count: Int
    var visibleCardsCount: Int
    @Binding var rotation: Int
    
    @State private var offset: CGFloat = .zero
    @State private var viewSize: CGSize = .zero
    
    func body(content: Content) -> some View {
        let extraOffset = -min(CGFloat(index) * 20, CGFloat(visibleCardsCount) * 20)
        let scale = 1 - min(CGFloat(index) * 0.07, CGFloat(visibleCardsCount) * 0.07)
        let rotationDegree: CGFloat = 30
        let dragRotation = max(min(offset / max(viewSize.width, 1), 1), 0) * rotationDegree
        
        content
            .onGeometryChange(for: CGSize.self, of: { $0.size }, action: { viewSize = $0 })
            .offset(x: extraOffset)
            .scaleEffect(scale, anchor: .leading)
            .animation(.smooth(duration: 0.25, extraBounce: 0), value: index)
            .offset(x: offset)
            .rotation3DEffect(.init(degrees: dragRotation), axis: (0, 1, 0), anchor: .center, perspective: 0.5)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Only allow right-side swipes
                        offset = max(value.translation.width, 0)
                    }
                    .onEnded { value in
                        let xVelocity = max(value.velocity.width / 5, 0)
                        
                        if (offset + xVelocity) > (viewSize.width * 0.65) {
                            pushToNextCard()
                        } else {
                            withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                                offset = .zero
                            }
                        }
                    },
                isEnabled: index == 0 && count > 1
            )
    }
    
    @MainActor
    private func pushToNextCard() {
        withAnimation(.smooth(duration: 0.25, extraBounce: 0).logicallyComplete(after: 0.15), completionCriteria: .logicallyComplete) {
            offset = viewSize.width
        } completion: {
            rotation += 1
            withAnimation(.smooth(duration: 0.25, extraBounce: 0)) {
                offset = .zero
            }
        }
    }
}

private extension RandomAccessCollection {
    func rotateFromLeft(by steps: Int) -> [Element] {
        guard !isEmpty else { return [] }
        let moveIndex = steps % count
        return Array(Array(self)[moveIndex...]) + Array(Array(self)[0..<moveIndex])
    }
}

// Cards Content
struct StatCardContent: View {
    let stat: AllergyStat
    let cardBackground: Color

    var body: some View {
        VStack(spacing: 20) {
            if !stat.before.isEmpty {
                Text(stat.before)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }

            Image(stat.image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 160)

            if !stat.after.isEmpty {
                Text(stat.after)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(cardBackground)
    }
}

#Preview("Portrait") {
    AllergiesStatsView(onNext: {})
        .environment(AppSettings())
        .environment(SpeechManager())
}

#Preview("Landscape", traits: .landscapeLeft) {
    AllergiesStatsView(onNext: {})
        .environment(AppSettings())
        .environment(SpeechManager())
}
