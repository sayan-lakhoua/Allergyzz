// Apple Developer Documentation used for EAIView:
// https://developer.apple.com/documentation/swiftui/view/task(priority:_:)

import SwiftUI

// Introduces the EAI and teaches "Blue to the Sky, Orange to the Thigh"
struct EAIView: View {
    var onNext: () -> Void
    
    @Environment(SpeechManager.self) private var speech
    
    private let introText = "This is an epinephrine auto-injector. This special device is full of a hormone called adrenaline which shocks the body and can stop a dangerous allergic reaction and can save someone's life."
    private let bsotText = "Remember, Blue to the Sky, Orange to the Thigh! The blue safety cap points up toward the sky, and the orange tip goes against the outer thigh to deliver the injection. Keep your hand away from the orange tip."
    
    @State private var showBSOT = false
    
    private var currentText: String {
        showBSOT ? bsotText : introText
    }
    
    private var currentImage: String {
        showBSOT ? "epinephrineAutoInjectorBSOTAllergyzz" : "epinephrineAutoInjectorAllergyzz"
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                BackgroundColorView()
                
                Image(currentImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height * 0.92, alignment: .bottom)
                    .clipped()
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .animation(.easeInOut(duration: 0.4), value: showBSOT)
                
                VStack {
                    Spacer()
                    
                    DialogueBox(
                        text: currentText,
                        expression: .talking,
                        isTalking: speech.isSpeaking,
                        showNextButton: showBSOT,
                        onNext: onNext
                    )
                }
            }
        }
        .ignoresSafeArea()
        .task {
            await speech.speakAndWait(introText)
            withAnimation {
                showBSOT = true
            }
            speech.speak(bsotText)
        }
    }
}

#Preview {
    EAIView(onNext: {})
        .environment(AppSettings())
        .environment(SpeechManager())
}
