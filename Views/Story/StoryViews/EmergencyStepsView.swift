// Apple Developer Documentation used for EmergencyStepsView:
// https://developer.apple.com/documentation/swiftui/view/task(priority:_:)
// https://developer.apple.com/documentation/swift/task/sleep(for:)

import SwiftUI

// Shows the three emergency steps one by one with a timed reveal (123)
struct EmergencyStepsView: View {
    var onNext: () -> Void
    
    @Environment(SpeechManager.self) private var speech
    @Environment(AppSettings.self) private var settings
    @State private var showStep = 0
    @State private var showReaction = false
    @State private var showNextButton = false
    
    let dialogueText = "If someone is having an anaphylactic reaction, here's what you need to do..."
    
    var body: some View {
        ZStack {
            BackgroundColorView()
            
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    EmergencyStepRow(number: 1, color: .red, text: "Call emergency services immediately", isVisible: showStep >= 1, font: settings.font)
                    EmergencyStepRow(number: 2, color: .orange, text: "Use the epinephrine auto-injector", isVisible: showStep >= 2, font: settings.font)
                    EmergencyStepRow(number: 3, color: Color(red: 0.93, green: 0.69, blue: 0.13), text: "Stay with the person until help arrives", isVisible: showStep >= 3, font: settings.font)
                }
                .padding(.horizontal, 24)
                .padding(.top, 120)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                DialogueBox(
                    text: dialogueText,
                    expression: speech.isSpeaking ? .talking : (showReaction ? .stressed : .talking),
                    isTalking: speech.isSpeaking,
                    showNextButton: showNextButton,
                    onNext: onNext
                )
            }
        }
        .onAppear { speech.speak(dialogueText) }
        .task {
            for i in 1...3 {
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation(.spring(response: 0.5)) {
                    showStep = i
                }
            }
            // Extra delay before showing the NEXT button
            try? await Task.sleep(for: .seconds(2.0))
            withAnimation {
                showNextButton = true
            }
        }
        .onChange(of: speech.isSpeaking) { _, isSpeaking in
            if !isSpeaking {
                showReaction = true
            }
        }
    }
}

// Steps stcked in vertical row
struct EmergencyStepRow: View {
    let number: Int
    let color: Color
    let text: String
    let isVisible: Bool
    let font: AppFont
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackground: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private var numberForeground: Color {
        .white
    }
    
    var body: some View {
        if isVisible {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(color).frame(width: 50, height: 50)
                    Text("\(number)").font(.title2.bold()).foregroundStyle(numberForeground)
                }
                
                Text(text)
                    .font(font.font(.body))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 16))
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }
}

#Preview {
    EmergencyStepsView(onNext: {})
        .environment(AppSettings())
        .environment(SpeechManager())
}
