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
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let distortion = AVAudioUnitDistortion()
    private var loopBuffer: AVAudioPCMBuffer?
    private(set) var isPlaying = false

    init() {
        engine.attach(player)
        engine.attach(distortion)
        distortion.loadFactoryPreset(.multiBrokenSpeaker)
        distortion.wetDryMix = 18

        let format = AVAudioFormat(
            standardFormatWithSampleRate: 44_100,
            channels: 2
        )!
        try? engine.connectNode(player, to: distortion, format: format)
        try? engine.connectNode(
            distortion,
            to: engine.mainMixerNode,
            format: format
        )
        engine.mainMixerNode.outputVolume = 0.22
        loopBuffer = Self.makeLoop(format: format)
    }

    func play() {
        guard !isPlaying, let loopBuffer else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .gameChat,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            player.scheduleBuffer(loopBuffer, at: nil, options: .loops)
            try player.playAudio(at: nil)
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    func stop() {
        player.stop()
        engine.pause()
        isPlaying = false
    }

    func setEnabled(_ isEnabled: Bool) {
        isEnabled ? play() : stop()
    }

    private static func makeLoop(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let beatsPerMinute = 148.0
        let beatDuration = 60.0 / beatsPerMinute
        let loopDuration = beatDuration * 8
        let frameCount = AVAudioFrameCount(sampleRate * loopDuration)

        guard
            let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: frameCount
            ),
            let channels = buffer.floatChannelData
        else {
            return nil
        }
        buffer.frameLength = frameCount

        let riff: [Double] = [
            82.41, 82.41, 98.0, 73.42, 82.41, 110.0, 98.0, 73.42,
        ]
        let subdivision = beatDuration / 2

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let step = Int(time / subdivision) % riff.count
            let localTime = time.truncatingRemainder(dividingBy: subdivision)
            let envelope = exp(-localTime * 11)
            let frequency = riff[step]

            let fundamental = sin(2 * .pi * frequency * time)
            let harmonic = sin(2 * .pi * frequency * 2 * time) * 0.42
            let guitar = tanh((fundamental + harmonic) * 3.4) * envelope * 0.32

            let beatPosition = time.truncatingRemainder(
                dividingBy: beatDuration
            )
            let kickEnvelope = exp(-beatPosition * 24)
            let kickFrequency = 48 + 70 * exp(-beatPosition * 30)
            let kick = sin(2 * .pi * kickFrequency * time) * kickEnvelope * 0.46

            let eighthPosition = time.truncatingRemainder(
                dividingBy: subdivision
            )
            let hatEnvelope = exp(-eighthPosition * 70)
            let noiseSeed = sin(Double(frame) * 12.9898) * 43_758.5453
            let noise = (noiseSeed - floor(noiseSeed)) * 2 - 1
            let hat = noise * hatEnvelope * 0.08

            let sample = Float(max(-0.9, min(0.9, guitar + kick + hat)))
            channels[0][frame] = sample
            channels[1][frame] = sample * 0.96
        }
        return buffer
    }
}
