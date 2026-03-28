// Apple Developer Documentation used for NotAloneView:
// https://developer.apple.com/documentation/swiftui/geometryreader

import SwiftUI

// The final page of the story with the Not Alone message
struct NotAloneView: View {
    var onNext: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                BackgroundColorView()

                Image("notAloneAllergyzz")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    Text("You're not alone")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                        .multilineTextAlignment(.center)
                    
                    Spacer().frame(height: 40)
                    
                    Button {
                        onNext()
                    } label: {
                        Text("FINISH")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(height: 95)
                            .frame(width: 120)
                            .padding(.horizontal, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(red: 0x32/255.0, green: 0x71/255.0, blue: 0xEA/255.0))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 50)
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    NotAloneView(onNext: {})
        .environment(AppSettings())
}
