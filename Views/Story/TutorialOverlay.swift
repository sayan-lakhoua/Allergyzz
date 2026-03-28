// Apple Developer Documentation used for TutorialOverlay:
// https://developer.apple.com/documentation/swiftui/viewmodifier
// https://developer.apple.com/documentation/swiftui/binding

import SwiftUI

// Shows the hint GIF
// autoDismiss = true: goes away after the GIF plays once (first-time hint).
// autoDismiss = false: stays until the user taps it (replaying via the hint (?) button).
struct HintOverlay: ViewModifier {
    let gifName: String
    @Binding var isPresented: Bool
    var autoDismiss: Bool = false

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                GIFImageView(gifName: gifName, repeatCount: 1)
                    .ignoresSafeArea()
                    .allowsHitTesting(true)
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.25)) {
                            isPresented = false
                        }
                    }
                    .transition(.identity)
                    .zIndex(999)
                    .task {
                        guard autoDismiss else { return }
                        // Wait for the GIF to play through once (~3s covers all current hint GIFs)
                        try? await Task.sleep(for: .seconds(3))
                        guard isPresented else { return }
                        withAnimation(.easeOut(duration: 0.25)) {
                            isPresented = false
                        }
                    }
            }
        }
    }
}

extension View {
    func hintOverlay(gifName: String, isPresented: Binding<Bool>, autoDismiss: Bool = false) -> some View {
        modifier(HintOverlay(gifName: gifName, isPresented: isPresented, autoDismiss: autoDismiss))
    }
}
