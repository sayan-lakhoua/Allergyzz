// Apple Developer Documentation used for AnaphylacticExplanationView:
// https://developer.apple.com/documentation/swiftui/view/symboleffect(_:options:isactive:)
// https://developer.apple.com/documentation/swiftui/viewthatfits

import SwiftUI

// Shows animated SF Symbols that change as speech progresses through the explanation
struct AnaphylacticExplanationView: View {
    var onNext: () -> Void
    
    @Environment(SpeechManager.self) private var speech
    @Environment(AppSettings.self) private var settings

    @State private var activeSymbol: SymbolPhase = .bloodPressure

    private let narration = [
        "The person's blood pressure drops dangerously low, and the heart beats super fast trying to compensate.",
        "At the same time, the airways in the lungs narrow, making it really hard to breathe.",
        "Without quick treatment, this can be life-threatening, which is why emergency help is needed immediately!"
    ].joined(separator: " ")

    // Each case are representing a symbol
    enum SymbolPhase: Int {
        case bloodPressure
        case heart
        case lungs
        case warning
        case emergency
    }

    var body: some View {
        GeometryReader { geo in
            let isPortrait = geo.size.height > geo.size.width
            ZStack {
                BackgroundColorView()

                VStack {
                    Spacer()

                    AnaphylacticSymbolView(phase: activeSymbol, isPortrait: isPortrait)
                        .transition(.scale.combined(with: .opacity))

                    Spacer()

                    DialogueBox(
                        text: narration,
                        expression: speech.isSpeaking ? .talking : .stressed,
                        isTalking: speech.isSpeaking,
                        showNextButton: true,
                        onNext: onNext
                    )
                }
            }
        }
        .onAppear {
            speech.speak(narration)
        }
        .onChange(of: speech.currentWord) { _, newWord in
            updateSymbol(for: newWord)
        }
    }

    // Manages the SF symbols
    private func updateSymbol(for word: String) {
        let next: SymbolPhase
        if word.contains("blood")       { next = .bloodPressure }
        else if word.contains("heart")  { next = .heart }
        else if word.contains("airway") { next = .lungs }
        else if word.contains("threaten") { next = .warning }
        else if word.contains("emergency") { next = .emergency }
        else { return }

        guard next.rawValue > activeSymbol.rawValue else { return }

        withAnimation {
            activeSymbol = next
        }
    }
}

struct AnaphylacticSymbolView: View {
    let phase: AnaphylacticExplanationView.SymbolPhase
    let isPortrait: Bool
    
    private var symbolSize: CGFloat {
        isPortrait ? 120 : 280
    }
    
    var body: some View {
        Group {
            switch phase {
            case .bloodPressure:
                Image(systemName: "arrowshape.down.fill")
                    .symbolEffect(.wiggle, options: .repeating, isActive: true)
                    .foregroundStyle(.orange)
            case .heart:
                Image(systemName: "heart.fill")
                    .symbolEffect(.bounce, options: .repeating.speed(2), isActive: true)
                    .foregroundStyle(.red)
            case .lungs:
                Image(systemName: "lungs.fill")
                    .symbolEffect(.breathe, options: .repeating, isActive: true)
                    .symbolRenderingMode(.multicolor)
            case .warning:
                Image(systemName: "exclamationmark.triangle.fill")
                    .symbolEffect(.wiggle, options: .repeating, isActive: true)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .yellow)
            case .emergency:
                Image(systemName: "staroflife.fill")
                    .symbolEffect(.bounce, value: phase)
                    .foregroundStyle(.blue)
            }
        }
        .font(.system(size: symbolSize))
    }
}

#Preview {
    AnaphylacticExplanationView(onNext: {})
        .environment(AppSettings())
        .environment(SpeechManager())
}
