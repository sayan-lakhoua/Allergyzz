// Apple Developer Documentation used for SpeechManager:
// https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer
// https://developer.apple.com/documentation/avfaudio/avspeechsynthesizerdelegate
// https://developer.apple.com/documentation/avfaudio/avspeechutterance

import AVFoundation

// SpeechManager handles TTS for Clearus' speeches
@MainActor @Observable
final class SpeechManager: NSObject, AVSpeechSynthesizerDelegate {
    
    // These are read by views to drive animations and word highlighting (in blue in the DialogueBox)
    var isSpeaking = false
    var currentWord = ""
    var spokenRange: Range<String.Index>?
    // Goes from 0.0 to 1.0 as speech progresses (used for auto-scrolling if custom font or text too long to be shown in DialogueView)
    var speechProgress: Double = 0
    
    // This is a workaround to make that if speed is chnaged mid-speech it starts the speech again from the current position. Before this was implemented we had to wait for the next speech to start with the new speed
    var speakingRate: Float = AVSpeechUtteranceDefaultSpeechRate {
        didSet {
            if oldValue != speakingRate && isSpeaking {
                restartFromCurrentPosition()
            }
        }
    }
    
    var isMuted: Bool = false {
        didSet {
            if oldValue != isMuted && isSpeaking {
                restartFromCurrentPosition()
            }
        }
    }
    
    private let synthesizer = AVSpeechSynthesizer()
    
    // The original full text passed to speak() to highlit words
    private var fullText: String?
    
    // If restarted mid-speech it restart only with the remaining text
    private var charOffset: Int = 0
    
    // Each utterance gets a generation ID
    private var currentUtteranceID: Int = 0
    private var utteranceIDs: [ObjectIdentifier: Int] = [:]
    
    // Used by speakAndWait() to pause the caller until speech finishes
    private var continuation: CheckedContinuation<Void, Never>?
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String) {
        finishContinuation()
        cancelCurrentUtterance()
        beginSpeaking(text)
    }
    
    // Speak text and wait until it finishes. Used to sequence multiple lines.
    func speakAndWait(_ text: String) async {
        finishContinuation()
        cancelCurrentUtterance()
        // Small delay
        try? await Task.sleep(for: .milliseconds(50))
        
        beginSpeaking(text)
        
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
    
    func stop() {
        finishContinuation()
        cancelCurrentUtterance()
        fullText = nil
        isSpeaking = false
        currentWord = ""
        spokenRange = nil
    }
    
    // "Forgets" the generation ID so old delegate callbacks get ignored, then stops
    private func cancelCurrentUtterance() {
        currentUtteranceID += 1
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    private func beginSpeaking(_ text: String) {
        fullText = text
        charOffset = 0
        currentWord = ""
        spokenRange = nil
        speechProgress = 0
        isSpeaking = true
        
        let utterance = makeUtterance(text)
        currentUtteranceID += 1
        utteranceIDs[ObjectIdentifier(utterance)] = currentUtteranceID
        synthesizer.speak(utterance)
    }
    
    // Re-speaks from the current position at the new rate/volume
    private func restartFromCurrentPosition() {
        guard let text = fullText, isSpeaking else { return }
        
        let idx = min(Int(speechProgress * Double(text.count)), text.count)
        let remaining = String(text[text.index(text.startIndex, offsetBy: idx)...])
        guard !remaining.isEmpty else { return }
        
        charOffset = idx
        
        currentUtteranceID += 1
        synthesizer.stopSpeaking(at: .immediate)
        
        let utterance = makeUtterance(remaining)
        utteranceIDs[ObjectIdentifier(utterance)] = currentUtteranceID
        synthesizer.speak(utterance)
    }
    
    private func makeUtterance(_ text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speakingRate
        utterance.volume = isMuted ? 0 : 1
        return utterance
    }
    
    private func isCurrentUtterance(_ id: ObjectIdentifier) -> Bool {
        utteranceIDs[id] == currentUtteranceID
    }
    
    private func cleanupUtterance(_ id: ObjectIdentifier) {
        utteranceIDs.removeValue(forKey: id)
    }
    
    private func finishContinuation() {
        let c = continuation
        continuation = nil
        c?.resume()
    }
    
    // All delegate callbacks are nonisolated because AVSpeechSynthesizerDelegate calls them from a background thread.
    
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didStart utterance: AVSpeechUtterance
    ) {
        let uid = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard self.isCurrentUtterance(uid) else { return }
            self.isSpeaking = true
        }
    }
    
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        let uid = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard self.isCurrentUtterance(uid) else {
                self.cleanupUtterance(uid)
                return
            }
            self.cleanupUtterance(uid)
            self.isSpeaking = false
            self.speechProgress = 1.0
            self.currentWord = ""
            self.spokenRange = nil
            self.fullText = nil
            self.finishContinuation()
        }
    }
    
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        let uid = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard self.isCurrentUtterance(uid) else {
                self.cleanupUtterance(uid)
                return
            }
            self.cleanupUtterance(uid)
            self.isSpeaking = false
            self.speechProgress = 0
            self.currentWord = ""
            self.spokenRange = nil
            self.finishContinuation()
        }
    }
    
    // Called before each word is spoken. This is used to highlight words in blue in the dialogue box
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        let utteranceText = utterance.speechString
        guard let localRange = Range(characterRange, in: utteranceText) else { return }
        let word = String(utteranceText[localRange]).lowercased()
        let uid = ObjectIdentifier(utterance)
        
        Task { @MainActor in
            guard self.isCurrentUtterance(uid) else { return }
            guard let full = self.fullText else { return }
    
            let location = characterRange.location + self.charOffset
            let mapped = NSRange(location: location, length: characterRange.length)
            
            if let range = Range(mapped, in: full) {
                self.spokenRange = range
            }
            
            self.speechProgress = Double(location + characterRange.length) / Double(full.count)
            self.currentWord = word
        }
    }
}
