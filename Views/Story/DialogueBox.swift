// Apple Developer Documentation used for DialogueBox:
// https://developer.apple.com/documentation/swiftui/scrollviewreader
// https://developer.apple.com/documentation/swiftui/preferencekey
// https://developer.apple.com/documentation/swiftui/fullscreencover

import SwiftUI

private let dialogueBoxHeight: CGFloat = 100
private let dialogueBoxCharacterSize: CGFloat = 100
private let nextButtonWidth: CGFloat = 80
private let dialogueBoxHorizontalPadding: CGFloat = 24
private let dialogueBoxBottomPadding: CGFloat = 50

// The main dialogue UI at the bottom of each story page.Shows Clearus, the spoken text with word highlighting, and the NEXT button.
struct DialogueBox: View {
    let text: String
    let expression: ClearusExpression
    let isTalking: Bool
    var showCharacter: Bool = true
    var showNextButton: Bool = false
    var onNext: (() -> Void)? = nil
    
    @Environment(AppSettings.self) var settings
    @Environment(SpeechManager.self) var speech
    @Environment(\.colorScheme) var colorScheme
    @State private var showFullTextSheet = false
    @State private var textSize: CGSize = .zero
    @State private var isNextButtonVisible = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var isClearusTapped = false
    
    private var boxBackgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    // Spoken word highlighted in accent color
    private var highlightedText: Text {
        guard let range = speech.spokenRange,
              range.lowerBound >= text.startIndex,
              range.upperBound <= text.endIndex else {
            return Text(text).foregroundStyle(textColor)
        }
        
        let before = String(text[text.startIndex..<range.lowerBound])
        let highlighted = Text(text[range]).foregroundStyle(Color.accentColor).bold()
        let after = String(text[range.upperBound..<text.endIndex])
        
        return Text("\(Text(before))\(highlighted)\(Text(after))")
            .foregroundStyle(textColor)
    }
    
    // Clearus animation
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if showCharacter {
                ImmuneCellAnimatedView(
                    expression: expression,
                    size: dialogueBoxCharacterSize,
                    isTalking: isTalking
                )
                .scaleEffect(isClearusTapped ? 0.85 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.4), value: isClearusTapped)
                .onTapGesture {
                    isClearusTapped = true
                    Task {
                        try? await Task.sleep(for: .milliseconds(150))
                        isClearusTapped = false
                    }
                }
            }
            
            // Shows the Text scroll view for accessibility
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    highlightedText
                        .font(settings.font.font(.title3))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, minHeight: dialogueBoxHeight, alignment: .leading)
                        .padding(.horizontal, 12)
                        .background(
                            GeometryReader { textGeo in
                                Color.clear
                                    .preference(key: TextSizeKey.self, value: textGeo.size)
                            }
                        )
                        .id("text")
                }
                .scrollDisabled(textSize.height <= dialogueBoxHeight)
                .onAppear { scrollProxy = proxy }
                .onPreferenceChange(TextSizeKey.self) { size in
                    textSize = size
                }
                .onChange(of: speech.speechProgress) { _, progress in
                    if progress > 0 && textSize.height > dialogueBoxHeight {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("text", anchor: UnitPoint(x: 0, y: progress))
                        }
                    }
                }
            }
            .frame(height: dialogueBoxHeight)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(boxBackgroundColor)
            )
            .clipShape(.rect(cornerRadius: 24))
            // Tapping the text opens a full-screen sheet for easier reading
            .onTapGesture {
                showFullTextSheet = true
            }
            
            if isNextButtonVisible {
                Button {
                    onNext?()
                } label: {
                    Text("NEXT")
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
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, dialogueBoxHorizontalPadding)
        .padding(.bottom, dialogueBoxBottomPadding)
        .fullScreenCover(isPresented: $showFullTextSheet) {
            FullTextSheet(text: text, font: settings.font)
                .portraitOverlay()
        }
        .onChange(of: speech.isSpeaking) { _, isSpeaking in
            if !isSpeaking && speech.speechProgress >= 1.0 {
                if textSize.height > dialogueBoxHeight {
                    withAnimation(.easeOut(duration: 0.3)) {
                        scrollProxy?.scrollTo("text", anchor: .bottom)
                    }
                }
                if showNextButton {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isNextButtonVisible = true
                    }
                }
            }
        }
        .onChange(of: textSize) { _, size in
            // Keep scroll pinned to bottom when text reflows after speech ends
            if !speech.isSpeaking && size.height > dialogueBoxHeight {
                withAnimation(.easeOut(duration: 0.3)) {
                    scrollProxy?.scrollTo("text", anchor: .bottom)
                }
            }
        }
        .onChange(of: showNextButton) { _, show in
            if show && !speech.isSpeaking {
                withAnimation(.easeOut(duration: 0.3)) {
                    isNextButtonVisible = true
                }
            }
        }
        .onChange(of: text) { _, _ in
            isNextButtonVisible = false
        }
    }
}

private struct TextSizeKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// Full-screen sheet that shows the dialogue text in a larger, scrollable format
struct FullTextSheet: View {
    let text: String
    let font: AppFont
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(font.font(.title))
                    .multilineTextAlignment(.leading)
                    .padding(32)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Full Text")
            .navigationBarTitleDisplayMode(.inline)
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

#Preview {
    DialogueBox(
        text: "Hello! I'm Clearus",
        expression: .talking,
        isTalking: true
    )
    .environment(AppSettings())
    .environment(SpeechManager())
}
