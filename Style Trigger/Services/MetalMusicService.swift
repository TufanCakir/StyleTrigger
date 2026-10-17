//
//  MetalMusicService.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import AVFAudio
import Foundation

@MainActor
final class MetalMusicService {
    private enum AudioConfiguration {
        static let sampleRate = 44_100.0
        static let channels: AVAudioChannelCount = 2
        static let volume: Float = 0.22
        static let bpm = 148.0
        static let beatsPerLoop = 8
    }
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let distortion = AVAudioUnitDistortion()
    private var loopBuffer: AVAudioPCMBuffer?
    private var isEnabled = false
    private var playbackGeneration = 0
    private var activationTask: Task<Void, Never>?
    private var observers: [NSObjectProtocol] = []
    private(set) var isPlaying = false
    private(set) var lastError: String?
    init() {
        guard
            let format = AVAudioFormat(
                standardFormatWithSampleRate: AudioConfiguration.sampleRate,
                channels: AudioConfiguration.channels
            )
        else {
            lastError = "Could not create audio format."
            return
        }
        engine.attach(player)
        engine.attach(distortion)
        distortion.loadFactoryPreset(.multiBrokenSpeaker)
        distortion.wetDryMix = 18
        do {
            if #available(iOS 27.0, *) {
                try engine.connectNode(player, to: distortion, format: format)
                try engine.connectNode(
                    distortion,
                    to: engine.mainMixerNode,
                    format: format
                )
            } else {
                engine.connect(player, to: distortion, format: format)
                engine.connect(
                    distortion,
                    to: engine.mainMixerNode,
                    format: format
                )
            }
        } catch {
            lastError =
                "Could not configure audio engine: \(error.localizedDescription)"
            return
        }
        engine.mainMixerNode.outputVolume = AudioConfiguration.volume
        loopBuffer = Self.makeLoop(format: format)
        installAudioObservers()
    }
    func play() {
        isEnabled = true
        guard !isPlaying, activationTask == nil else { return }
        guard loopBuffer != nil else {
            lastError = lastError ?? "Audio loop is unavailable."
            return
        }
        let generation = playbackGeneration
        activationTask = Task { [weak self] in
            // Session configuration and activation must not block the UI thread.
            let activationResult = await Task.detached(priority: .userInitiated)
            {
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(
                        .ambient,
                        mode: .default,
                        options: [.mixWithOthers]
                    )
                    try session.setActive(true)
                    return Optional<String>.none
                } catch {
                    return Optional(error.localizedDescription)
                }
            }.value
            guard let self else { return }
            self.activationTask = nil
            guard self.isEnabled, self.playbackGeneration == generation else {
                return
            }
            if let activationResult {
                self.lastError = activationResult
                self.isPlaying = false
                return
            }
            self.startEnginePlayback()
        }
    }
    private func startEnginePlayback() {
        guard let loopBuffer, isEnabled else { return }
        do {
            if !engine.isRunning { try engine.start() }
            player.stop()
            player.scheduleBuffer(loopBuffer, at: nil, options: [.loops])
            if #available(iOS 27.0, *) {
                try player.playAudio()
            } else {
                player.play()
            }
            isPlaying = true
            lastError = nil
        } catch {
            player.stop()
            engine.pause()
            isPlaying = false
            lastError = error.localizedDescription
        }
    }
    func stop() {
        isEnabled = false
        playbackGeneration &+= 1
        activationTask?.cancel()
        activationTask = nil
        stopPlayback()
    }
    func setEnabled(_ enabled: Bool) {
        enabled ? play() : stop()
    }
    func setVolume(_ volume: Float) {
        guard volume.isFinite else { return }
        engine.mainMixerNode.outputVolume = min(max(volume, 0), 1)
    }
    /// Call when permanently disposing of the service.
    func shutdown() {
        stop()
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
        engine.stop()
        Task.detached(priority: .utility) {
            try? AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        }
    }
    private func stopPlayback() {
        player.stop()
        engine.pause()
        isPlaying = false
    }
    private func installAudioObservers() {
        let center = NotificationCenter.default
        let session = AVAudioSession.sharedInstance()
        if #available(iOS 27.0, *) {
            observers.append(
                center.addObserver(
                    forName: AVAudioSession.didBecomeInactiveNotification,
                    object: session,
                    queue: .main
                ) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        self?.stopPlayback()
                    }
                }
            )
            observers.append(
                center.addObserver(
                    forName: AVAudioSession
                        .resumptionRecommendationNotification,
                    object: session,
                    queue: .main
                ) { [weak self] notification in
                    // Read the Sendable value BEFORE crossing into the actor.
                    let shouldResume =
                        (notification.userInfo?[
                            AVAudioSession.resumptionContextKey
                        ]
                        as? AVAudioSession.ResumptionContext)?.recommendation
                        == .shouldResume
                    Task { @MainActor [weak self] in
                        guard let self, self.isEnabled, shouldResume else {
                            return
                        }
                        self.play()
                    }
                }
            )
        } else {
            observers.append(
                center.addObserver(
                    forName: AVAudioSession.interruptionNotification,
                    object: session,
                    queue: .main
                ) { [weak self] notification in
                    // UInt is Sendable; Notification / userInfo are not.
                    let rawType =
                        notification.userInfo?[
                            AVAudioSessionInterruptionTypeKey
                        ] as? UInt
                    let rawOptions =
                        notification.userInfo?[
                            AVAudioSessionInterruptionOptionKey
                        ] as? UInt ?? 0
                    Task { @MainActor [weak self] in
                        self?.handleLegacyInterruption(
                            type: rawType,
                            options: rawOptions
                        )
                    }
                }
            )
        }
        observers.append(
            center.addObserver(
                forName: .AVAudioEngineConfigurationChange,
                object: engine,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.player.stop()
                    self.isPlaying = false
                    if self.isEnabled { self.play() }
                }
            }
        )
    }
    private func handleLegacyInterruption(
        type rawType: UInt?,
        options rawOptions: UInt
    ) {
        guard let rawType else { return }
        switch rawType {
        case 1:  // AVAudioSessionInterruptionType.began
            stopPlayback()
        case 0:  // AVAudioSessionInterruptionType.ended
            let options = AVAudioSession.InterruptionOptions(
                rawValue: rawOptions
            )
            if isEnabled && options.contains(.shouldResume) { play() }
        default:
            break
        }
    }
    private static func makeLoop(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let beatDuration = 60.0 / AudioConfiguration.bpm
        let duration = beatDuration * Double(AudioConfiguration.beatsPerLoop)
        let frameCount = AVAudioFrameCount((sampleRate * duration).rounded())
        guard
            let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: frameCount
            ),
            let channels = buffer.floatChannelData,
            frameCount > 0
        else { return nil }
        buffer.frameLength = frameCount
        let riff: [Double] = [82.41, 82.41, 98, 73.42, 82.41, 110, 98, 73.42]
        let subdivision = beatDuration / 2
        let fadeFrames = min(Int(sampleRate * 0.008), Int(frameCount) / 2)
        var noiseState: UInt32 = 0xC0FFEE
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let step = Int(time / subdivision) % riff.count
            let localTime = time.truncatingRemainder(dividingBy: subdivision)
            let envelope = exp(-localTime * 11)
            let frequency = riff[step]
            let fundamental = sin(2 * Double.pi * frequency * time)
            let harmonic = sin(4 * Double.pi * frequency * time) * 0.42
            let guitar = tanh((fundamental + harmonic) * 3.4) * envelope * 0.32
            let beatPosition = time.truncatingRemainder(
                dividingBy: beatDuration
            )
            let kickEnvelope = exp(-beatPosition * 24)
            let kickFrequency = 48 + 70 * exp(-beatPosition * 30)
            let kick =
                sin(2 * Double.pi * kickFrequency * beatPosition) * kickEnvelope
                * 0.46
            let hatEnvelope = exp(-localTime * 70)
            noiseState = 1_664_525 &* noiseState &+ 1_013_904_223
            let noise = Double(noiseState) / Double(UInt32.max) * 2 - 1
            let hat = noise * hatEnvelope * 0.08
            // Smooth the boundary between repeated buffers to reduce clicks.
            let fade: Double
            if fadeFrames > 0 && frame < fadeFrames {
                fade = Double(frame) / Double(fadeFrames)
            } else if fadeFrames > 0 && frame >= Int(frameCount) - fadeFrames {
                fade = Double(Int(frameCount) - 1 - frame) / Double(fadeFrames)
            } else {
                fade = 1
            }
            let sample = Float(
                max(-0.9, min(0.9, (guitar + kick + hat) * fade))
            )
            channels[0][frame] = sample
            channels[1][frame] = sample * 0.96
        }
        return buffer
    }
}
