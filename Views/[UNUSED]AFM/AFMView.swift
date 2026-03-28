// Apple Developer Documentation used for AFMView:
// https://developer.apple.com/documentation/foundationmodels
// https://developer.apple.com/documentation/foundationmodels/languagemodelsession

import SwiftUI

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
struct AIMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

// A chat interface where the user can ask Clearus questions about allergies
// using on-device language models (iOS 26+)
@available(iOS 26.0, *)
struct AFMView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    
    @State private var messages: [AIMessage] = []
    @State private var questionText = ""
    @State private var isLoading = false
    @State private var session: LanguageModelSession?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages) { msg in
                                MessageBubble(message: msg, font: settings.font)
                            }
                            if isLoading {
                                ThinkingBubble(font: settings.font)
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    ChatInputField(
                        text: $questionText,
                        isLoading: isLoading,
                        font: settings.font,
                        onSend: { Task { await sendMessage() } }
                    )
                }
            }
            .navigationTitle("Ask Clearus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark", role: .confirm) {
                        dismiss()
                    }
                    .tint(.accentColor)
                }
            }
        }
        .task { await setup() }
    }
    
    private func setup() async {
        let model = SystemLanguageModel.default
        guard model.isAvailable else { return }
        
        session = LanguageModelSession(
            instructions: "You are Clearus, a friendly immune cell who helps children learn about allergies. Keep responses simple and encouraging."
        )
        
        messages.append(AIMessage(
            text: "Hello! I'm Clearus, your friendly immune cell! Ask me anything about allergies!",
            isUser: false
        ))
    }
    
    private func sendMessage() async {
        let text = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let session else { return }
        
        questionText = ""
        messages.append(AIMessage(text: text, isUser: true))
        isLoading = true
        
        do {
            let response = try await session.respond(to: text)
            messages.append(AIMessage(text: response.content, isUser: false))
        } catch {
            messages.append(AIMessage(text: "Oops! Could you try asking again?", isUser: false))
        }
        
        isLoading = false
    }
}

// A single chat bubble - blue for user, gray for Clearus
@available(iOS 26.0, *)
struct MessageBubble: View {
    let message: AIMessage
    let font: AppFont
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isUser {
                Spacer(minLength: 60)
            } else {
                ImmuneCellAnimatedView(expression: .happy, size: 36, isTalking: false)
            }
            
            Text(message.text)
                .font(font.font(.body))
                .foregroundStyle(message.isUser ? Color.white : Color.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(message.isUser ? Color.blue : Color(.systemGray5))
                .clipShape(.rect(cornerRadius: 20))
            
            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal)
    }
}

// Shows a loading spinner while Clearus is thinking
@available(iOS 26.0, *)
struct ThinkingBubble: View {
    let font: AppFont
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                ProgressView().scaleEffect(0.8)
                Text("Thinking...")
                    .font(font.font(.subheadline))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(.capsule)
            Spacer()
        }
        .padding(.horizontal)
    }
}

// The text input field at the bottom of the chat
@available(iOS 26.0, *)
struct ChatInputField: View {
    @Binding var text: String
    let isLoading: Bool
    let font: AppFont
    let onSend: () -> Void
    
    var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    var body: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundStyle(.secondary)
            
            TextField("Ask a question...", text: $text)
                .textFieldStyle(.plain)
                .font(font.font(.body))
                .submitLabel(.send)
                .onSubmit { onSend() }
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canSend ? Color.blue : Color.secondary)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(.capsule)
        .padding()
    }
}

@available(iOS 26.0, *)
#Preview {
    AFMView()
        .environment(AppSettings())
}
#endif
