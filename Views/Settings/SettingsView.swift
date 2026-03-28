// Apple Developer Documentation used for SettingsView:
// https://developer.apple.com/documentation/swiftui/navigationstack
// https://developer.apple.com/documentation/swiftui/list
// https://developer.apple.com/documentation/swiftui/toggle
// https://developer.apple.com/documentation/swiftui/slider

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    
    var body: some View {
        @Bindable var settings = settings
        
        NavigationStack {
            List {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Image("appIconSettingsAllergyzz")
                                .resizable()
                                .frame(width: 140, height: 140)
                                .clipShape(.rect(cornerRadius: 30))
                            
                            VStack(spacing: 4) {
                                Text("Allergyzz")
                                    .styled(.title, with: settings)
                                    .bold()
                                
                                Text("Allergies made simple")
                                    .styled(.subheadline, with: settings)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 24)
                    .listRowBackground(Color.clear)
                }
                
                Section {
                    Toggle("Bold Text", systemImage: "bold", isOn: $settings.boldText)
                    
                    NavigationLink {
                        TextSizeView()
                    } label: {
                        Label("Larger Text", systemImage: "textformat.size")
                    }
                    
                    NavigationLink {
                        FontPickerView()
                    } label: {
                        LabeledContent {
                            Text(settings.font.rawValue)
                        } label: {
                            Label("Font Style", systemImage: "textformat")
                        }
                    }
                } header: {
                    Label("Accessibility", systemImage: "accessibility")
                        .foregroundStyle(.blue)
                }
                
                Section {
                    HStack(spacing: 40) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Button { settings.appearance = appearance } label: {
                                VStack(spacing: 12) {
                                    Image(appearance.image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 120)
                                        .clipShape(.rect(cornerRadius: 12))
                                    
                                    Text(appearance.rawValue)
                                        .styled(.subheadline, with: settings)
                                    
                                    Image(systemName: settings.appearance == appearance ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(
                                            settings.appearance == appearance ? Color.white : Color.secondary,
                                            settings.appearance == appearance ? Color.accentColor : Color.secondary
                                        )
                                        .contentTransition(.symbolEffect(.replace))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } header: {
                    Label("Appearance", systemImage: "moonphase.last.quarter")
                }
                
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "swift")
                            .styled(.title, with: settings)
                            .foregroundStyle(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Swift Student Challenge")
                                .styled(.headline, with: settings)
                            Text("2026 Submission")
                                .styled(.caption, with: settings)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Image("sayanLakhouaSettings")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .clipShape(.rect(cornerRadius: 6))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sayan Lakhoua")
                                .styled(.headline, with: settings)
                        }
                    }
                } header: {
                    Label("About", systemImage: "info.circle")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") {
                        dismiss()
                    }
                    .tint(.accentColor)
                }
            }
        }
    }
}

// Lets the user adjust text size with a slider and live preview
struct TextSizeView: View {
    @Environment(AppSettings.self) var settings
    
    var body: some View {
        @Bindable var settings = settings
        
        List {
            Section {
                VStack(spacing: 24) {
                    Text("Text with Accessibility settings")
                        .styled(.title2, with: settings)
                        .bold(settings.boldText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                    
                    HStack {
                        Image(systemName: "textformat.size.smaller")
                            .foregroundStyle(.secondary)
                        Slider(value: $settings.textSize, in: 0.8...1.4, step: 0.1)
                        Image(systemName: "textformat.size.larger")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical)
            } footer: {
                Text("Drag the slider to adjust text size.")
            }
        }
        .navigationTitle("Larger Text")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Lets the user pick between system font, OpenDyslexic, or Lexend
struct FontPickerView: View {
    @Environment(AppSettings.self) var settings
    
    var body: some View {
        @Bindable var settings = settings
        
        List {
            Section {
                ForEach(AppFont.allCases) { font in
                    Button {
                        settings.font = font
                    } label: {
                        HStack {
                            Text(font.rawValue)
                                .font(font.font(.body))
                                .foregroundStyle(.primary)
                            Spacer()
                            if settings.font == font {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            } footer: {
                Text("OpenDyslexic and Lexend are designed to improve readability.")
            }
        }
        .navigationTitle("Font Style")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environment(AppSettings())
}
