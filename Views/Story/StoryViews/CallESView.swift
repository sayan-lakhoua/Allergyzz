// Apple Developer Documentation used for CallESView:
// https://developer.apple.com/documentation/swiftui/draggesture
// https://developer.apple.com/documentation/swiftui/view/contentshape(_:eofill:)
// https://developer.apple.com/documentation/swiftui/view/contenttransition(_:)

import SwiftUI

// Interactive Emergency SOS on iPhone page where the user holds two buttons and/or slides to call
struct CallESView: View {

    let onComplete: () -> Void
    @Binding var showHint: Bool
    var hintAutoDismiss: Bool

    @Environment(SpeechManager.self) private var speech
    @Environment(AppSettings.self) private var settings

    @State private var isHoldingLeft = false
    @State private var isHoldingRight = false
    @State private var showSOSScreen = false
    @State private var done = false
    @State private var holdCountdown = 8
    @State private var holdProgress = 0.0
    @State private var holdTimerActive = false
    @State private var holdTask: Task<Void, Never>?
    @State private var isDraggingSlider = false
    @State private var sliderRatio = 0.0

    let initialText = "Quick, we have to call Emergency Services! Let's use the Emergency SOS feature on iPhone."
    let holdingText = "Now slide the SOS slider or keep holding both buttons to call emergency services."
    let completedText = "Emergency Services have been called, they're on their way."
    
    private var areBothButtonsHeld: Bool {
        isHoldingLeft && isHoldingRight
    }

    var body: some View {
        GeometryReader { geo in
            let isPortrait = geo.size.height > geo.size.width
            let phoneHeight: CGFloat = {
                if isPortrait {
                    return min(geo.size.height * 0.60, geo.size.width * 1.2)
                } else {
                    return geo.size.height * 0.78
                }
            }()
            let phoneWidth = phoneHeight * 0.49

            ZStack {
                BackgroundColorView()

                VStack(spacing: 0) {
                    Spacer().frame(height: geo.size.height * 0.05)
                    PhoneArea(
                        phoneWidth: phoneWidth,
                        phoneHeight: phoneHeight,
                        showSOSScreen: showSOSScreen,
                        done: done,
                        isHoldingLeft: $isHoldingLeft,
                        isHoldingRight: $isHoldingRight,
                        sliderRatio: $sliderRatio,
                        isDraggingSlider: $isDraggingSlider,
                        holdTimerActive: holdTimerActive,
                        holdProgress: holdProgress,
                        holdCountdown: holdCountdown,
                        onSliderCompleted: { finishInteraction() }
                    )
                    Spacer()
                    DialogueBox(
                        text: dialogueText,
                        expression: done ? .happy : .talking,
                        isTalking: speech.isSpeaking,
                        showNextButton: done,
                        onNext: onComplete
                    )
                }

            }
        }
        .ignoresSafeArea()
        .onAppear { speech.speak(initialText) }
        .onChange(of: speech.isSpeaking) { _, isSpeaking in
            // Show the hint after speech finishes if interaction hasn't started
            if !isSpeaking && !showSOSScreen && !done && !showHint {
                Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    guard !showSOSScreen, !done, !showHint else { return }
                    withAnimation { showHint = true }
                }
            }
        }
        .onChange(of: showSOSScreen) { _, started in
            if started && showHint {
                withAnimation { showHint = false }
            }
        }
        .hintOverlay(gifName: "animationSOSiPhoneAllergyzz", isPresented: $showHint, autoDismiss: hintAutoDismiss)
        .onChange(of: areBothButtonsHeld) { _, bothHeld in
            if bothHeld && !showSOSScreen {
                withAnimation(.easeInOut(duration: 0.3)) { showSOSScreen = true }
                speech.speak(holdingText)
                startHoldCountdown()
            } else if bothHeld && showSOSScreen && !done && !holdTimerActive {
                startHoldCountdown()
            } else if !bothHeld {
                withAnimation(.easeOut(duration: 0.3)) {
                    holdTimerActive = false
                    holdProgress = 0
                    holdCountdown = 8
                }
            }
        }
    }

    private func finishInteraction() {
        guard !done else { return }
        withAnimation { done = true }
        holdTimerActive = false
        holdTask?.cancel()
        holdTask = nil
        speech.speak(completedText)
    }

    private func startHoldCountdown() {
        guard !done else { return }
        holdCountdown = 8
        holdProgress = 0
        holdTimerActive = true
        holdTask?.cancel()

        holdTask = Task {
            for step in 1...160 {
                try? await Task.sleep(for: .milliseconds(50))
                guard !Task.isCancelled, areBothButtonsHeld, !done, !isDraggingSlider else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        holdTimerActive = false
                        holdProgress = 0
                        holdCountdown = 8
                    }
                    return
                }
                let progress = Double(step) / 160.0
                holdProgress = progress
                holdCountdown = max(0, 8 - Int(progress * 8))
                if step == 160 { finishInteraction() }
            }
        }
    }

    private var dialogueText: String {
        if done {
            completedText
        } else if showSOSScreen {
            holdingText
        } else {
            initialText
        }
    }
}

// iPhone with side buttons and SOS screen
struct PhoneArea: View {
    let phoneWidth: CGFloat
    let phoneHeight: CGFloat
    let showSOSScreen: Bool
    let done: Bool
    @Binding var isHoldingLeft: Bool
    @Binding var isHoldingRight: Bool
    @Binding var sliderRatio: Double
    @Binding var isDraggingSlider: Bool
    let holdTimerActive: Bool
    let holdProgress: Double
    let holdCountdown: Int
    let onSliderCompleted: () -> Void
    
    var body: some View {
        ZStack {
            Image(showSOSScreen ? "iPhoneSOSAllergyzz" : "iPhoneAppleParkAllergyzz")
                .resizable()
                .scaledToFit()
                .frame(height: phoneHeight)

            if !done {
                ArrowButton(systemName: "arrow.right", isHolding: $isHoldingLeft, inwardDirection: 1)
                    .offset(x: -(phoneWidth / 2 + 28), y: -phoneHeight * 0.10)
                ArrowButton(systemName: "arrow.left", isHolding: $isHoldingRight, inwardDirection: -1)
                    .offset(x: phoneWidth / 2 + 28, y: -phoneHeight * 0.14)
            }

            if showSOSScreen && !done {
                VStack(spacing: 12) {
                    Text("Keep Holding to Call\nEmergency Services")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    SOSSlider(
                        ratio: $sliderRatio,
                        isDragging: $isDraggingSlider,
                        holdProgress: holdTimerActive ? holdProgress : nil,
                        countdownValue: holdTimerActive ? holdCountdown : nil,
                        onCompleted: onSliderCompleted
                    )
                    .frame(width: phoneWidth * 0.7, height: 44)

                    Text("Slide to call Emergency Services")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .offset(y: -phoneHeight * 0.10)
            }

            if done {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .green)
            }
        }
    }
}

// Press-and-hold arrows buttons on the side of the iPhone
struct ArrowButton: View {
    let systemName: String
    @Binding var isHolding: Bool
    var inwardDirection: CGFloat = 1

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 48, weight: .bold))
            .foregroundStyle(.red)
            .frame(width: 60, height: 60)
            .contentShape(Rectangle())
            .offset(x: isHolding ? inwardDirection * 10 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isHolding)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !isHolding { isHolding = true } }
                    .onEnded { _ in isHolding = false }
            )
    }
}

// The SOS slider that the user drags to complete the call / or that moves while user is holding btns
struct SOSSlider: View {
    @Binding var ratio: Double
    @Binding var isDragging: Bool
    var holdProgress: Double? = nil
    var countdownValue: Int? = nil
    var onCompleted: () -> Void

    private let thumbSize: CGFloat = 38

    private var displayPosition: CGFloat {
        if !isDragging, let hp = holdProgress { return hp }
        return ratio
    }

    var body: some View {
        GeometryReader { geo in
            let maxOffset = geo.size.width - thumbSize

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: thumbSize / 2)
                    .foregroundStyle(ratio >= 0.95 ? .green : .red.opacity(0.8))

                Circle()
                    .foregroundStyle(.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay { SOSThumbIcon(ratio: ratio, countdownValue: countdownValue, isDragging: isDragging) }
                    .offset(x: maxOffset * displayPosition)
                    .gesture(
                        DragGesture()
                            .onChanged { drag in
                                isDragging = true
                                let newRatio = drag.translation.width / maxOffset
                                ratio = min(max(newRatio, 0), 1)
                                if ratio >= 0.95 { onCompleted() }
                            }
                            .onEnded { _ in
                                isDragging = false
                                if ratio < 0.95 {
                                    withAnimation(.spring(response: 0.3)) { ratio = 0 }
                                }
                            }
                    )
            }
            .frame(height: thumbSize)
            .frame(maxHeight: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: (thumbSize + 2) / 2)
                    .stroke(ratio >= 0.95 ? .green : .red, lineWidth: 2)
                    .frame(height: thumbSize + 2)
            )
        }
    }
}

// The icon inside the SOS slider thumb (shows SOS or countdown)
struct SOSThumbIcon: View {
    let ratio: Double
    let countdownValue: Int?
    let isDragging: Bool
    
    var body: some View {
        if ratio >= 0.95 {
            Image(systemName: "checkmark")
                .font(.body.weight(.bold))
                .foregroundStyle(.green)
        } else if let countdown = countdownValue, !isDragging {
            Text("\(countdown)")
                .font(.callout.weight(.bold))
                .foregroundStyle(.red)
                .contentTransition(.numericText())
        } else {
            Image(systemName: "sos")
                .font(.caption.weight(.bold))
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    CallESView(onComplete: {}, showHint: .constant(false), hintAutoDismiss: true)
        .environment(AppSettings())
        .environment(SpeechManager())
}
