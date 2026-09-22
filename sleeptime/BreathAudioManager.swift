import Foundation
import AVFoundation
import Combine

class BreathAudioManager: ObservableObject {
    private var engine: AVAudioEngine
    private var sourceNode: AVAudioSourceNode?
    
    // For smooth transitions
    private var targetPhase: Float = 0.0 // 0.0 to 1.0
    private var currentPhase: Float = 0.0
    private var displayLink: CADisplayLink?
    
    // Audio engine state
    private var isPlaying = false
    
    // Synthesis state (must be captured by the render block)
    private var renderPhase: Double = 0.0
    private let sampleRate: Double = 44100.0
    
    init() {
        engine = AVAudioEngine()
        setupEngine()
    }
    
    private func setupEngine() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let phaseStep = 1.0 / self.sampleRate
            
            // Base frequency: 108 Hz
            let fundamentalFreq: Double = 108.0
            // Create a very slow beating effect (Delta wave, ~1.5 Hz) for deep relaxation
            let detuneOffset: Double = 1.5
            
            for frame in 0..<Int(frameCount) {
                // Get the smoothed current phase from the main thread
                let breathIntensity = Double(self.currentPhase)
                
                // Deep base drone: much softer baseline, swells warmly
                let baseVolume = 0.15 + (breathIntensity * 0.25)
                
                // Harmonics fade in extremely gently to add a "halo" of sound
                let harmonic1Volume = breathIntensity * 0.10 // 216 Hz
                let harmonic2Volume = breathIntensity * 0.05 // 324 Hz
                let harmonic3Volume = breathIntensity * 0.02 // 432 Hz
                
                // Synthesize Sine waves
                let time = self.renderPhase
                
                // Dual fundamental for a natural, acoustic "beating" (like a Tibetan bowl)
                let base1 = sin(2.0 * .pi * fundamentalFreq * time)
                let base2 = sin(2.0 * .pi * (fundamentalFreq + detuneOffset) * time)
                let val1 = ((base1 + base2) / 2.0) * baseVolume
                
                let val2 = sin(2.0 * .pi * (fundamentalFreq * 2.0) * time) * harmonic1Volume
                let val3 = sin(2.0 * .pi * (fundamentalFreq * 3.0) * time) * harmonic2Volume
                let val4 = sin(2.0 * .pi * (fundamentalFreq * 4.0) * time) * harmonic3Volume
                
                // Combine
                var sample = Float(val1 + val2 + val3 + val4)
                
                // Extremely soft clipping for tape-like warmth (avoids digital harshness)
                sample = tanh(sample) * 0.4
                
                for buffer in ablPointer {
                    let buf = UnsafeMutableBufferPointer<Float>(buffer)
                    buf[frame] = sample
                }
                
                self.renderPhase += phaseStep
            }
            return noErr
        }
        
        self.sourceNode = node
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        
        do {
            engine.mainMixerNode.outputVolume = 0.0 // Start muted, fade in
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func start() {
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Failed to start audio engine: \(error)")
            }
        }
        engine.mainMixerNode.outputVolume = 1.0
        isPlaying = true
        startDisplayLink()
    }
    
    func stop() {
        engine.mainMixerNode.outputVolume = 0.0
        isPlaying = false
        stopDisplayLink()
    }
    
    // Call this to sync audio with breath phase (0.0 to 1.0)
    // 0.0 = deep exhale (pure, quiet 432Hz), 1.0 = deep inhale (bright, loud harmonics)
    func setBreathPhase(_ phase: Float) {
        targetPhase = max(0.0, min(1.0, phase))
    }
    
    // Smoothly interpolate the intensity over time to avoid audio pops or sudden jumps
    private func startDisplayLink() {
        stopDisplayLink()
        displayLink = CADisplayLink(target: self, selector: #selector(updatePhase))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updatePhase() {
        let smoothingFactor: Float = 0.05
        currentPhase += (targetPhase - currentPhase) * smoothingFactor
    }
}
