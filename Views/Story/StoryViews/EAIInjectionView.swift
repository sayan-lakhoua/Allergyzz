// Apple Developer Documentation used for EAIInjectionView:
// https://developer.apple.com/documentation/swiftui/draggesture
// https://developer.apple.com/documentation/swiftui/view/contenttransition(_:)

import SwiftUI

// Interactive page where the user holds the screen to complete the epinephrine injection
struct EAIInjectionView: View {
    let onComplete: () -> Void
    @Binding var showHint: Bool
    var hintAutoDismiss: Bool
    
    @Environment(SpeechManager.self) private var speech
    @Environment(MusicManager.self) private var musicManager
    @State private var step = 1
    @State private var holdProgress = 0.0
    @State private var isHolding = false
    @State private var done = false
    @State private var waitingForHold = false
    @State private var holdTask: Task<Void, Never>?
    
    private let holdDuration = 3.0
    
    let stepDialogues = [
        "Position the epinephrine auto-injector at a 90-degree angle.",
        "Then push the needle into the thigh until you hear a \"click\".",
        "Hold in place for 3 seconds."
    ]
    let completedText = "You did it! The injection is complete."
    
    // The image changes based on which step/state
    private var displayImageName: String {
        if done {
            return "epinephrineAutoInjectorStep03Allergyzz"
        }
        if isHolding {
            return "epinephrineAutoInjectorStep04Allergyzz"
        }
        return "epinephrineAutoInjectorStep0\(step)Allergyzz"
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                BackgroundColorView()
                
                Image(displayImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                
                // Full-screen hold gesture area
                if waitingForHold && !done {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in startHold() }
                                .onEnded { _ in stopHold() }
                        )
                }
                
                if waitingForHold && !done {
                    InjectionHoldButton(
                        holdProgress: holdProgress,
                        isHolding: isHolding,
                        holdDuration: holdDuration,
                        onStartHold: { startHold() },
                        onStopHold: { stopHold() }
                    )
                }
                
                if done {
                    InjectionCheckmark()
                }
                
                VStack {
                    Spacer()
                    DialogueBox(
                        text: currentDialogue,
                        expression: done ? .happy : .talking,
                        isTalking: speech.isSpeaking,
                        showNextButton: done,
                        onNext: onComplete
                    )
                }
            }
        }
        .ignoresSafeArea()
        .task { await playSteps() }
        .onChange(of: waitingForHold) { _, waiting in
            // Show the hint once the hold interaction becomes available
            if waiting && !done && !showHint {
                Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    guard waitingForHold, !done, !showHint else { return }
                    withAnimation { showHint = true }
                }
            }
        }
        .onChange(of: isHolding) { _, holding in
            if holding && showHint {
                withAnimation { showHint = false }
            }
        }
        .hintOverlay(gifName: "animationInjectionAllergyzz", isPresented: $showHint, autoDismiss: hintAutoDismiss)
    }
    
    var currentDialogue: String {
        if done { return completedText }
        return stepDialogues[min(step - 1, stepDialogues.count - 1)]
    }
    
    // Speaks each step in sequence, then enables the hold interaction
    func playSteps() async {
        for s in 1...stepDialogues.count {
            step = s
            await speech.speakAndWait(stepDialogues[s - 1])
            if s < stepDialogues.count {
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
        waitingForHold = true
    }
    
    func startHold() {
        guard !isHolding && !done else { return }
        isHolding = true
        musicManager.playSFX("clickEAIAllergyzz")
        holdTask?.cancel()
        
        holdTask = Task {
            let totalSteps = 200
            let interval = Int(holdDuration * 1000) / totalSteps
            
            for i in 1...totalSteps {
                try? await Task.sleep(for: .milliseconds(interval))
                guard !Task.isCancelled, isHolding else { return }
                
                holdProgress = Double(i) / Double(totalSteps)
                
                if i == totalSteps {
                    done = true
                    isHolding = false
                    holdTask = nil
                    speech.speak(completedText)
                }
            }
        }
    }
    
    func stopHold() {
        if done { return }
        isHolding = false
        holdProgress = 0
        holdTask?.cancel()
        holdTask = nil
    }
}

// The circular hold button with a progress ring and countdown
struct InjectionHoldButton: View {
    let holdProgress: Double
    let isHolding: Bool
    let holdDuration: Double
    let onStartHold: () -> Void
    let onStopHold: () -> Void
    
    var body: some View {
        HStack {
            VStack(spacing: 16) {
                Spacer()
                
                if isHolding {
                    Text("\(Int(ceil(holdDuration * (1 - holdProgress))))")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .contentTransition(.numericText())
                        .animation(.default, value: Int(ceil(holdDuration * (1 - holdProgress))))
                }
                
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(Color.white, lineWidth: 8)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .background(Circle().fill(Color(red: 0x32/255.0, green: 0x71/255.0, blue: 0xEA/255.0)))
                    .overlay {
                        if !isHolding {
                            Image(systemName: "hand.tap.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.white)
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in onStartHold() }
                            .onEnded { _ in onStopHold() }
                    )
                
                Spacer().frame(height: 200)
            }
            .padding(.leading, 40)
            
            Spacer()
        }
    }
}

struct InjectionCheckmark: View {
    var body: some View {
        HStack {
            VStack(spacing: 16) {
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 120))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .green)
                
                Spacer().frame(height: 200)
            }
            .padding(.leading, 40)
            
            Spacer()
        }
    }
}

#Preview {
    EAIInjectionView(onComplete: {}, showHint: .constant(false), hintAutoDismiss: true)
        .environment(AppSettings())
        .environment(SpeechManager())
}
