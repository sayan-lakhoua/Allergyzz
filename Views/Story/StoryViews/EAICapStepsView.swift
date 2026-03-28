// Apple Developer Documentation used for EAICapStepsView:
// https://developer.apple.com/documentation/swiftui/draggesture
// https://developer.apple.com/documentation/swiftui/appstorage

import SwiftUI

// Interactive page where the user drags up the slider to remove the blue safety cap from the EAI
struct EAICapStepsView: View {
    let onComplete: () -> Void
    @Binding var showHint: Bool
    var hintAutoDismiss: Bool
    
    @Environment(SpeechManager.self) private var speech
    @State private var sliderValue = 0.0
    @State private var done = false
    @State private var sliderCompleted = false
    @State private var showSlider = true
    @AppStorage("hintShown_eaiCapStepsView") private var hintShown = false
    
    let initialText = "To use it, you need to pull off the blue safety cap. Slide up to pull the cap!"
    let completedText = "Perfect"
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                BackgroundColorView()
                
                Image("epinephrineAutoInjectorCapOpenStep0\(frameNumber)Allergyzz")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                
                if showSlider {
                    // Full-screen drag area so the user can drag anywhere
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 5)
                                .onChanged { value in
                                    guard !done else { return }
                                    let dragHeight = geo.size.height * 0.6
                                    let verticalMovement = -value.translation.height
                                    let newValue = min(max(verticalMovement / dragHeight, 0), 1)
                                    sliderValue = newValue
                                    
                                    if newValue >= 0.95 && !done {
                                        completeSlider()
                                    }
                                }
                                .onEnded { _ in
                                    if !done {
                                        withAnimation(.spring(response: 0.3)) {
                                            sliderValue = 0
                                        }
                                    }
                                }
                        )
                    
                    CapRemovalSlider(
                        sliderValue: $sliderValue,
                        sliderCompleted: sliderCompleted,
                        geoSize: geo.size
                    )
                }
                
                VStack {
                    Spacer()
                    
                    DialogueBox(
                        text: done ? completedText : initialText,
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
            // Show the hint after speech finishes if the cap hasn't been removed yet
            if !isSpeaking && !done && !showHint {
                Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    guard !done, !showHint else { return }
                    withAnimation { showHint = true }
                }
            }
        }
        .onChange(of: done) { _, isDone in
            if isDone && showHint {
                withAnimation { showHint = false }
            }
        }
        .hintOverlay(gifName: "animationVSliderAllergyzz", isPresented: $showHint, autoDismiss: hintAutoDismiss)
    }
    
    // Maps slider progress to one of 6 image frames so it feels like we're removing it
    var frameNumber: Int {
        min(Int(sliderValue * 5) + 1, 6)
    }
    
    private func completeSlider() {
        withAnimation {
            sliderCompleted = true
            done = true
            sliderValue = 1.0
        }
        if showHint { showHint = false }
        speech.speak(completedText)
        
        // Hide the slider after a short delay
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation {
                showSlider = false
            }
        }
    }
}

// Slider's position
struct CapRemovalSlider: View {
    @Binding var sliderValue: Double
    var sliderCompleted: Bool
    var geoSize: CGSize
    
    var body: some View {
        GeometryReader { geo in
            VerticalCapSlider(value: $sliderValue, isCompleted: sliderCompleted)
                .frame(width: 60, height: geo.size.height * 0.6)
                .position(x: geo.size.width * 0.13, y: geo.size.height * 0.42)
        }
        .allowsHitTesting(false)
    }
}

// Vertical blue slider
struct VerticalCapSlider: View {
    @Binding var value: Double
    var isCompleted: Bool = false
    
    private let thumbSize: CGFloat = 50
    private let lineWidth: CGFloat = 2
    private let trackColor = Color(red: 0.196, green: 0.443, blue: 0.918)
    private let accentBlue = Color(red: 0.027, green: 0.196, blue: 0.765)
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: thumbSize / 2)
                    .foregroundStyle(isCompleted ? .green : trackColor)
                
                Circle()
                    .foregroundStyle(.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay {
                        Image(systemName: isCompleted ? "checkmark" : "arrow.up")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(isCompleted ? .green : accentBlue)
                    }
                    .offset(y: -(proxy.size.height - thumbSize) * min(max(value, 0), 1))
            }
            .frame(width: thumbSize)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: (thumbSize + lineWidth) / 2)
                    .stroke(isCompleted ? .green : accentBlue, lineWidth: lineWidth)
                    .frame(width: thumbSize + lineWidth)
            )
        }
    }
}

#Preview {
    EAICapStepsView(onComplete: {}, showHint: .constant(false), hintAutoDismiss: true)
        .environment(AppSettings())
        .environment(SpeechManager())
}
