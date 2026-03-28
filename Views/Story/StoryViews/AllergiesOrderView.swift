// Apple Developer Documentation used for AllergiesOrderView:
// https://developer.apple.com/documentation/swiftui/lazyvgrid
// https://developer.apple.com/documentation/swiftui/draggesture
// https://developer.apple.com/documentation/swiftui/geometryreader

import SwiftUI

private struct AllergyItem: Identifiable, Equatable {
    let id: Int
    let name: String
    let image: String
    let correctRank: Int
}

private let allergyItems: [AllergyItem] = [
    .init(id: 0, name: "Pollen",    image: "pollenAllergyAllergyzz",    correctRank: 1),
    .init(id: 1, name: "Food",      image: "foodAllergyAllergyzz",      correctRank: 2),
    .init(id: 2, name: "Medicines", image: "medicinesAllergyAllergyzz", correctRank: 3),
    .init(id: 3, name: "Insects",   image: "insectsAllergyAllergyzz",   correctRank: 4)
]

private let poolOrder: [AllergyItem] = [1, 2, 3, 0].map { allergyItems[$0] }

// A drag-and-drop quiz where the user ranks allergies from most to least common
struct AllergiesOrderView: View {
    var onNext: () -> Void

    @Environment(SpeechManager.self) private var speech
    @Environment(AppSettings.self) private var settings
    @Environment(MusicManager.self) private var musicManager
    @Environment(\.colorScheme) private var colorScheme

    private let introText = "Before we continue, I have a little challenge for you! Based on what you know, which allergies do you think are the most common? Try to rank them from most common to least common."
    private let correctText = "WOW! You got them all right! Pollen allergies are the most common, followed by food, medicines, and insect allergies."
    private let wrongText = "Nice try! Here's the correct order: Pollen allergies are the most common, followed by food, medicines, and insect allergies."

    @State private var slots: [AllergyItem?] = [nil, nil, nil, nil]
    @State private var pool: [AllergyItem] = poolOrder
    @State private var draggingItem: AllergyItem?
    @State private var dragPosition: CGPoint = .zero
    @State private var slotFrames: [Int: CGRect] = [:]
    @State private var hoveredSlot: Int = -1
    @State private var didCheck = false
    @State private var isCorrect = false

    private let cardHeight: CGFloat = 60
    private let reservedHeight: CGFloat = 76 + 10 + 60 + 16

    private var allFilled: Bool { slots.allSatisfy { $0 != nil } }

    private var cardBG: Color {
        colorScheme == .dark ? Color(.systemGray5) : .white
    }

    var body: some View {
        ZStack {
            BackgroundColorView()

            VStack(spacing: 0) {
                Spacer()
                slotsGrid.padding(.bottom, 128)

                if !didCheck { poolArea }
                else { Color.clear.frame(height: reservedHeight) }

                DialogueBox(
                    text: didCheck ? (isCorrect ? correctText : wrongText) : introText,
                    expression: didCheck ? (isCorrect ? .amazed : .stressed) : .talking,
                    isTalking: speech.isSpeaking,
                    showNextButton: didCheck,
                    onNext: onNext
                )
            }
            .padding(.horizontal, 16)

            // Drag gesture for the draggable cards
            if let item = draggingItem {
                allergyCard(item, height: 44)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(cardBG))
                    .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
                    .scaleEffect(1.08)
                    .position(dragPosition)
                    .zIndex(100)
            }
        }
        .onAppear { speech.speak(introText) }
        .coordinateSpace(name: "orderView")
    }

    private func allergyCard(_ item: AllergyItem, height: CGFloat) -> some View {
        HStack(spacing: 8) {
            Image(item.image).resizable().scaledToFit().frame(height: height)
            Text(item.name)
                .font(settings.font.font(.callout).bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }

    private var slotsGrid: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 12
            let w = (geo.size.width - 5 * spacing) / 4
            let h = w * 0.65

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: 4), spacing: spacing) {
                ForEach(0..<4, id: \.self) { i in
                    slotCell(i, width: w, height: h)
                        .background(GeometryReader { g in
                            Color.clear
                                .onAppear { slotFrames[i] = g.frame(in: .named("orderView")) }
                                .onChange(of: g.frame(in: .named("orderView"))) { _, f in slotFrames[i] = f }
                        })
                }
            }
            .padding(.horizontal, spacing)
        }
        .frame(height: 130)
    }

    @ViewBuilder
    private func slotCell(_ index: Int, width: CGFloat, height: CGFloat) -> some View {
        if let item = slots[index] {
            allergyCard(item, height: height * 0.6)
                .frame(width: width, height: height)
                .background(RoundedRectangle(cornerRadius: 16).fill(slotColor(index)))
                .clipShape(.rect(cornerRadius: 16))
                .onTapGesture {
                    guard !didCheck else { return }
                    withAnimation(.spring(response: 0.3)) {
                        slots[index] = nil
                        pool.append(item)
                    }
                }
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        hoveredSlot == index ? Color.accentColor : .secondary.opacity(0.4),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(hoveredSlot == index ? Color.accentColor.opacity(0.1) : .clear)
                    )
                Text("\(index + 1)")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(hoveredSlot == index ? Color.accentColor : .secondary.opacity(0.5))
            }
            .frame(width: width, height: height)
        }
    }

    private func slotColor(_ index: Int) -> Color {
        guard didCheck, let item = slots[index] else { return cardBG }
        return item.correctRank == index + 1 ? .green.opacity(0.2) : .red.opacity(0.2)
    }

    private var poolArea: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(poolOrder) { item in
                    if pool.contains(where: { $0.id == item.id }) {
                        allergyCard(item, height: 40)
                            .frame(maxWidth: .infinity).frame(height: cardHeight)
                            .background(RoundedRectangle(cornerRadius: 16).fill(cardBG))
                            .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                            .opacity(draggingItem?.id == item.id ? 0.3 : 1)
                            .gesture(
                                DragGesture(coordinateSpace: .named("orderView"))
                                    .onChanged { v in
                                        if draggingItem == nil { draggingItem = item }
                                        dragPosition = v.location
                                        updateHover()
                                    }
                                    .onEnded { _ in drop() }
                            )
                    } else {
                        Color.clear.frame(maxWidth: .infinity).frame(height: cardHeight)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 76)

            if allFilled {
                Button { checkAnswer() } label: {
                    Text("CHECK")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: cardHeight)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(red: 0x32/255, green: 0x71/255, blue: 0xEA/255)))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                .transition(.scale.combined(with: .opacity))
            }
            Spacer(minLength: 0)
        }
        .frame(height: reservedHeight)
    }

    private func updateHover() {
        hoveredSlot = slotFrames.first { $0.value.contains(dragPosition) && slots[$0.key] == nil }?.key ?? -1
    }

    private func drop() {
        guard let item = draggingItem else { return }
        if hoveredSlot >= 0, hoveredSlot < 4, slots[hoveredSlot] == nil {
            withAnimation(.spring(response: 0.3)) {
                slots[hoveredSlot] = item
                pool.removeAll { $0.id == item.id }
            }
        }
        withAnimation(.spring(response: 0.3)) {
            draggingItem = nil
            hoveredSlot = -1
        }
    }

    private func checkAnswer() {
        isCorrect = slots.enumerated().allSatisfy { $0.element?.correctRank == $0.offset + 1 }
        withAnimation(.spring(response: 0.4)) { didCheck = true }

        musicManager.playSFX(isCorrect ? "correctAllergyzz" : "incorrectAllergyzz")
        speech.speak(isCorrect ? correctText : wrongText)
        if !isCorrect {
            // After a short delay, show the correct order to the user
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.spring(response: 0.5)) {
                    for item in allergyItems { slots[item.correctRank - 1] = item }
                    pool.removeAll()
                }
            }
        }
    }
}

#Preview {
    AllergiesOrderView(onNext: {})
        .environment(AppSettings())
        .environment(SpeechManager())
}
