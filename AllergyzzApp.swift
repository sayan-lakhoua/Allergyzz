import SwiftUI

@main
struct AllergyzzApp: App {
    @State private var settings = AppSettings()
    @State private var musicManager = MusicManager()
    @State private var splashDone = false
    
    init() {
        loadCustomFonts()
        preloadOnboardingGIFs()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                BackgroundColorView()
                    .ignoresSafeArea()
                
                if splashDone {
                    StoryHomeView()
                        .withAppSettings()
                        .preferredColorScheme(settings.appearance.colorScheme)
                        .environment(settings)
                        .environment(musicManager)
                        .portraitOverlay()
                        .transition(.opacity.animation(.easeIn(duration: 0.2)))
                }
                
                if !splashDone {
                    OnboardingView {
                        withAnimation { splashDone = true }
                    }
                    .preferredColorScheme(settings.appearance.colorScheme)
                    .environment(settings)
                }
            }
            .onAppear {
                if !settings.musicMuted {
                    musicManager.play()
                }
            }
        }
    }
}
