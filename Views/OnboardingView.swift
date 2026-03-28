// Apple Developer Documentation used for OnboardingView:
// https://developer.apple.com/documentation/swiftui/view/task(priority:_:)
// https://developer.apple.com/documentation/swift/task/sleep(for:)

import SwiftUI

// Shows the animated "allergyzz" text, then fades out and let the StoryHomeView shows up
struct OnboardingView: View {
    var onComplete: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var opacity: Double = 1

    // White and Black GIF depending on LM or DM
    private var gifName: String {
        colorScheme == .dark ? "allergyzzTextWGIFAllergyzz" : "allergyzzTextBGIFAllergyzz"
    }

    var body: some View {
        ZStack {
            BackgroundColorView()

            GIFImageView(gifName: gifName, repeatCount: 1)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
                .opacity(opacity)
        }
        .task {
            try? await Task.sleep(for: .seconds(6.0))
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 0
            }
            // Wait for fade to finish, then transition
            try? await Task.sleep(for: .seconds(0.2))
            onComplete()
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
