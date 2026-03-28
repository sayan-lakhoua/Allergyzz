// Apple Developer Documentation used for AppSettings:
// https://developer.apple.com/documentation/swiftui/font
// https://developer.apple.com/documentation/observation/observable()
// https://developer.apple.com/documentation/foundation/userdefaults
// https://developer.apple.com/documentation/swiftui/dynamictypesize
// https://developer.apple.com/documentation/coretext/ctfontmanagerregisterfontsforurl(_:_:_:)

//  Custom Fonts, OpenDyslexic and Lexend, licensed under the SIL Open Font License 1.1.
import SwiftUI
import CoreText
import AVFoundation

enum AppFont: String, CaseIterable, Identifiable {
    case system = "Default"
    case openDyslexic = "OpenDyslexic"
    case lexend = "Lexend"
    
    var id: String { rawValue }
    
    func font(_ style: Font.TextStyle) -> Font {
        switch self {
        case .system:
            return .system(style)
        case .openDyslexic:
            return .custom("OpenDyslexic", size: fontSize(for: style), relativeTo: style)
        case .lexend:
            return .custom("Lexend", size: fontSize(for: style), relativeTo: style)
        }
    }
    
    // These sizes match the default Dynamic Type sizes so custom fonts feel consistent
    func fontSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .subheadline: return 15
        case .body: return 17
        case .callout: return 16
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        default: return 17
        }
    }
}

enum SpeechSpeed: String, CaseIterable, Identifiable {
    case half = "0.5×"
    case normal = "1× (Default)"
    case oneAndHalf = "1.5×"
    case double = "2×"
    
    var id: String { rawValue }
    
    var shortLabel: String {
        switch self {
        case .half: return "0.5×"
        case .normal: return "1×"
        case .oneAndHalf: return "1.5×"
        case .double: return "2×"
        }
    }
    
    // Sppech Speed (AVSpeechUtterance) values (0.0 to 1.0), the default the speed is normally 0.5 however it felt a bit slow so I chnaged it to 0.54
    var utteranceRate: Float {
        switch self {
        case .half: return 0.35
        case .normal: return 0.54
        case .oneAndHalf: return 0.57
        case .double: return 0.65
        }
    }
}

// System, Light and Dark mode
enum AppAppearance: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { rawValue }
    
    var image: String {
        switch self {
        case .system: return "systemSettingsAppearance"
        case .light: return "lightSettingsAppearance"
        case .dark: return "darkSettingsAppearance"
        }
    }
    
    // nil selects System
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// Stores all user preferences and saves them to UserDefaults so they persist between launches
@Observable
final class AppSettings {
    var boldText: Bool = false {
        didSet { UserDefaults.standard.set(boldText, forKey: "boldText") }
    }
    
    var textSize: Double = 1.0 {
        didSet { UserDefaults.standard.set(textSize, forKey: "textSize") }
    }
    
    var font: AppFont = .system {
        didSet { UserDefaults.standard.set(font.rawValue, forKey: "font") }
    }
    
    var appearance: AppAppearance = .system {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: "appearance") }
    }
    
    var speechSpeed: SpeechSpeed = .normal {
        didSet { UserDefaults.standard.set(speechSpeed.rawValue, forKey: "speechSpeed") }
    }
    
    var speechMuted: Bool = false {
        didSet { UserDefaults.standard.set(speechMuted, forKey: "speechMuted") }
    }
    
    var musicMuted: Bool = false {
        didSet { UserDefaults.standard.set(musicMuted, forKey: "musicMuted") }
    }
    
    
    init() {
        boldText = UserDefaults.standard.bool(forKey: "boldText")
        
        let savedSize = UserDefaults.standard.double(forKey: "textSize")
        textSize = savedSize > 0 ? savedSize : 1.0
        
        if let savedFont = UserDefaults.standard.string(forKey: "font") {
            font = AppFont(rawValue: savedFont) ?? .system
        }
        
        if let savedAppearance = UserDefaults.standard.string(forKey: "appearance") {
            appearance = AppAppearance(rawValue: savedAppearance) ?? .system
        }
        
        if let savedSpeed = UserDefaults.standard.string(forKey: "speechSpeed") {
            speechSpeed = SpeechSpeed(rawValue: savedSpeed) ?? .normal
        }
        
        speechMuted = UserDefaults.standard.bool(forKey: "speechMuted")
        musicMuted = UserDefaults.standard.bool(forKey: "musicMuted")
    }
}

// Applies the user's font, bold, and text size choices across the whole app (apart from the navigationTitle as I prefered not using UIKit to make it custom)
struct AppTextModifier: ViewModifier {
    @Environment(AppSettings.self) var settings
    
    func body(content: Content) -> some View {
        content
            .font(settings.font.font(.body))
            .fontWeight(settings.boldText ? .semibold : .regular)
            .dynamicTypeSize(dynamicSize)
    }
    
    var dynamicSize: DynamicTypeSize {
        let size = settings.textSize
        if size < 0.85 { return .small }
        if size < 0.95 { return .medium }
        if size < 1.05 { return .large }
        if size < 1.15 { return .xLarge }
        if size < 1.25 { return .xxLarge }
        if size < 1.35 { return .xxxLarge }
        return .accessibility1
    }
}

// Loads custom fonts
func loadCustomFonts() {
    let fonts = [("OpenDyslexic", "otf"), ("Lexend", "ttf")]
    
    for (name, ext) in fonts {
        if let url = Bundle.main.url(forResource: name, withExtension: ext) ??
            Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources/Fonts") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension View {
    func withAppSettings() -> some View {
        modifier(AppTextModifier())
    }
    
    func styled(_ style: Font.TextStyle, with settings: AppSettings) -> some View {
        font(settings.font.font(style))
    }
}
