// Apple Developer Documentation used for GIFImageView:
// https://developer.apple.com/documentation/swiftui/uiviewrepresentable
// https://developer.apple.com/documentation/imageio/cgimagesource
// https://developer.apple.com/documentation/uikit/uiimage/animatedimage(with:duration:)

import SwiftUI
import UIKit
import ImageIO

// Caches that stores decoded GIF in memory so they display instantly
final class GIFStore: @unchecked Sendable {
    static let shared = GIFStore()
    private var cache: [String: UIImage] = [:]
    private var pending: Set<String> = []
    private let lock = NSLock()

    func get(_ name: String) -> UIImage? {
        lock.withLock { cache[name] }
    }

    func preload(_ name: String) {
        let shouldStart: Bool = lock.withLock {
            guard cache[name] == nil, !pending.contains(name) else { return false }
            pending.insert(name)
            return true
        }
        guard shouldStart else { return }
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let image = Self.decodeGIF(named: name)
            lock.withLock {
                if let image { cache[name] = image }
                pending.remove(name)
            }
        }
    }

    func waitForImage(_ name: String) async -> UIImage? {
        for _ in 0..<50 {
            if let image = get(name) { return image }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return get(name)
    }

    private static func decodeGIF(named name: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif"),
              let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let opts = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
        let count = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        var duration: Double = 0

        for i in 0..<count {
            guard let cg = CGImageSourceCreateImageAtIndex(source, i, opts) else { continue }
            let delay = frameDuration(at: i, source: source)
            duration += delay
            frames.append(UIImage(cgImage: cg))
        }

        guard !frames.isEmpty else { return nil }
        return UIImage.animatedImage(with: frames, duration: duration)
    }

    private static func frameDuration(at index: Int, source: CGImageSource) -> Double {
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gif = props[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return 0.1
        }
        if let t = gif[kCGImagePropertyGIFUnclampedDelayTime] as? Double, t > 0 { return t }
        if let t = gif[kCGImagePropertyGIFDelayTime] as? Double, t > 0 { return t }
        return 0.1
    }
}

// Pre-loads the GIFs so they show with min. lag (might still be laggy sometimes)
func preloadHintGIFs() {
    GIFStore.shared.preload("animationHandTapAllergyzz")
    GIFStore.shared.preload("animationSOSiPhoneAllergyzz")
    GIFStore.shared.preload("animationInjectionAllergyzz")
    GIFStore.shared.preload("animationVSliderAllergyzz")
}

// Pre-loads the "allergyzz" text animation GIFs
func preloadOnboardingGIFs() {
    GIFStore.shared.preload("allergyzzTextBGIFAllergyzz")
    GIFStore.shared.preload("allergyzzTextWGIFAllergyzz")
}

// Displays animated GIFs using UIImageView
struct GIFImageView: UIViewRepresentable {
    let gifName: String
    var repeatCount: Int = 0

    final class Coordinator {
        var isActive = true
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIImageView {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        iv.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        if let cached = GIFStore.shared.get(gifName) {
            configure(iv, with: cached)
        } else {
            let name = gifName
            let rpt = repeatCount
            let coordinator = context.coordinator
            GIFStore.shared.preload(name)
            Task { @MainActor in
                guard let image = await GIFStore.shared.waitForImage(name) else { return }
                guard coordinator.isActive else { return }
                iv.image = image.images?.first
                iv.animationImages = image.images
                iv.animationDuration = image.duration
                iv.animationRepeatCount = rpt
                iv.startAnimating()
            }
        }

        return iv
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}

    static func dismantleUIView(_ uiView: UIImageView, coordinator: Coordinator) {
        coordinator.isActive = false
        uiView.stopAnimating()
        uiView.animationImages = nil
    }

    private func configure(_ iv: UIImageView, with image: UIImage) {
        iv.image = image.images?.first
        iv.animationImages = image.images
        iv.animationDuration = image.duration
        iv.animationRepeatCount = repeatCount
        iv.startAnimating()
    }
}
