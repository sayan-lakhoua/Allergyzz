// Apple Developer Documentation used for PortraitOverlay:
// https://developer.apple.com/documentation/swiftui/viewmodifier
// https://developer.apple.com/documentation/swiftui/geometryreader

import SwiftUI

// Shows a "Rotate to Landscape" message when the device is in portrait mode as Allergyzz is better designed in landscape mode
struct PortraitOverlay: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    if geo.size.height > geo.size.width {
                        ZStack {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .ignoresSafeArea()

                            VStack(spacing: 20) {
                                Image(systemName: "rectangle.landscape.rotate")
                                    .font(.system(size: 80, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.accentColor)

                                VStack(spacing: 8) {
                                    Text("Rotate to Landscape")
                                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                        .foregroundStyle(Color.accentColor)

                                    Text("Allergyzz is best experienced in landscape mode.")
                                        .font(.system(.title3, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            }
    }
}

extension View {
    func portraitOverlay() -> some View {
        modifier(PortraitOverlay())
    }
}
