// Apple Developer Documentation used for ImmuneCellAnimatedView:
// https://developer.apple.com/documentation/swiftui/view/task(id:priority:_:)
// https://developer.apple.com/documentation/swiftui/view/drawinggroup(opaque:colormode:)

import SwiftUI

// Animates Clearus face to make it "speak" by using the 5 different frames
struct ImmuneCellAnimatedView: View {
    let expression: ClearusExpression
    let size: CGFloat
    let isTalking: Bool
    
    @State var currentFrame = 1
    
    let talkingFrames = 5
    let frameRate: Duration = .milliseconds(120)
    
    var body: some View {
        Image(expression == .talking ? "immuneCellState0\(currentFrame)Allergyzz" : expression.rawValue)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .drawingGroup()
            .task(id: "\(isTalking)-\(expression)") {
                guard isTalking && expression == .talking else {
                    currentFrame = 1
                    return
                }
                
                while !Task.isCancelled {
                    try? await Task.sleep(for: frameRate)
                    currentFrame = currentFrame % talkingFrames + 1
                }
            }
    }
}

#Preview {
    VStack(spacing: 40) {
        ImmuneCellAnimatedView(expression: .talking, size: 200, isTalking: true)
        ImmuneCellAnimatedView(expression: .sad1, size: 120, isTalking: false)
    }
}
