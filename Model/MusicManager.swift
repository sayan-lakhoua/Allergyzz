// Apple Developer Documentation used for MusicManager:
// https://developer.apple.com/documentation/avfaudio/avaudiosession
// https://developer.apple.com/documentation/avfaudio/avaudioplayer

import AVFoundation

@MainActor @Observable
final class MusicManager {
    private var audioPlayer: AVAudioPlayer?
    private(set) var isPlaying = false
    
    // Reduce volume so the speech can be heard clearly
    var volume: Float = 0.15 {
        didSet {
            audioPlayer?.volume = volume
        }
    }
    
    init() {
        setupAudioSession()
        loadMusic()
    }
    
    private func setupAudioSession() {
        do {
            // .mixWithOthers lets music play alongside speech synthesis
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
        }
    }
    
    private func loadMusic() {
        guard let url = Bundle.main.url(forResource: "AllergyzzMusic", withExtension: "mp3") else {
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
        } catch {
        }
    }
    
    func play() {
        guard let player = audioPlayer, !isPlaying else { return }
        player.play()
        isPlaying = true
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
    }
    
    func toggle() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    // SoundFX Helper
    private var sfxPlayers: [AVAudioPlayer] = []
    
    func playSFX(_ name: String, extension ext: String = "m4a", volume: Float = 1.0) {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.play()
            sfxPlayers.append(player)
            sfxPlayers.removeAll { !$0.isPlaying }
        } catch {
        }
    }
}
