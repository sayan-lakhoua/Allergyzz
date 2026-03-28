// Apple Developer Documentation used for BackgroundColorView:
// https://developer.apple.com/documentation/swiftui/color

import SwiftUI

// Blue background showing everywhere in the app
struct BackgroundColorView: View {
    var body: some View {
        Color(red: 0x67/255.0, green: 0x93/255.0, blue: 0xf9/255.0)
            .ignoresSafeArea()
            .opacity(0.3)
    }
}

#Preview {
    BackgroundColorView()
}
