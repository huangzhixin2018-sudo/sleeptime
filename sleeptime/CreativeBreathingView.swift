import SwiftUI
import Combine

enum BreathPhase {
    case ready
    case inhale
    case hold
    case exhale
    
    var title: String {
        switch self {
        case .ready: return "准备..."
        case .inhale: return "深吸气"
        case .hold: return "屏住呼吸"
        case .exhale: return "缓慢呼气"
        }
    }
}

struct CreativeBreathingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var tabBarVisibility: SleepTabBarVisibility
    @StateObject private var audioManager = BreathAudioManager()
    
    @State private var phase: BreathPhase = .ready
    @State private var breathScale: CGFloat = 0.3
    @State private var timeRemaining: Int = 4
    @State private var isActive: Bool = false
    
    @State private var bgColor: Color = Color(hex: "020617")
    
    // Animation properties
    @State private var rotation: Double = 0
    @State private var blobsScale: CGFloat = 0.8
    
    // Timer
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    // A faster timer for audio sync
    let syncTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    // UI Impact
    let hapticHeavy = UIImpactFeedbackGenerator(style: .heavy)
    let hapticLight = UIImpactFeedbackGenerator(style: .light)
    let hapticSoft = UIImpactFeedbackGenerator(style: .soft)
    
    var body: some View {
        ZStack {
            // Dynamic Background
            bgColor.ignoresSafeArea()
                .animation(.easeInOut(duration: phase == .inhale ? 4.0 : 4.0), value: bgColor)
            
            // Metaball-like fluid visualization
            ZStack {
                // Background subtle glow
                Circle()
                    .fill(Color(hex: "10b981").opacity(0.1))
                    .frame(width: 350, height: 350)
                    .scaleEffect(breathScale * 1.5)
                    .blur(radius: 50)
                
                // Orbiting Blob 1
                Circle()
                    .fill(Color(hex: "34d399"))
                    .frame(width: 150, height: 150)
                    .offset(x: 40 * breathScale, y: -40 * breathScale)
                    .rotationEffect(.degrees(rotation))
                
                // Orbiting Blob 2
                Circle()
                    .fill(Color(hex: "059669"))
                    .frame(width: 120, height: 120)
                    .offset(x: -50 * breathScale, y: 30 * breathScale)
                    .rotationEffect(.degrees(-rotation * 1.2))
                
                // Orbiting Blob 3
                Circle()
                    .fill(Color(hex: "6ee7b7"))
                    .frame(width: 100, height: 100)
                    .offset(x: 20 * breathScale, y: 60 * breathScale)
                    .rotationEffect(.degrees(rotation * 0.8))
                
                // Center Core
                Circle()
                    .fill(Color.white)
                    .frame(width: 80, height: 80)
                    .scaleEffect(blobsScale)
                    .blur(radius: 10)
            }
            .blur(radius: 30) // Extreme blur creates the metaball illusion
            .scaleEffect(breathScale)
            .animation(.easeInOut(duration: phase == .inhale ? 4.0 : (phase == .exhale ? 4.0 : 2.0)), value: breathScale)
            
            // UI Overlay
            VStack {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Text("灵息")
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    // Placeholder to balance the layout
                    Image(systemName: "xmark").opacity(0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Instructions
                VStack(spacing: 16) {
                    Text(phase.title)
                        .font(.system(size: 32, weight: .semibold, design: .serif))
                        .foregroundColor(.white)
                        .opacity(isActive ? 1.0 : 0.6)
                        .animation(.easeInOut(duration: 1.0), value: phase)
                        .transition(.opacity)
                        .id(phase.title) // Forces transition on change
                    
                    if isActive {
                        Text("\(timeRemaining)")
                            .font(.system(size: 28, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                            .contentTransition(.numericText())
                            .animation(.snappy, value: timeRemaining)
                    } else {
                        Text("点击下方按钮开始")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                // Start Button
                if !isActive {
                    Button(action: startBreathing) {
                        Text("开始共振")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(hex: "020617"))
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(30)
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            tabBarVisibility.isHidden = true
            // Start continuous rotation for the blobs
            withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                blobsScale = 1.2
            }
            
            hapticHeavy.prepare()
            hapticLight.prepare()
            hapticSoft.prepare()
        }
        .onDisappear {
            tabBarVisibility.isHidden = false
            isActive = false
            audioManager.stop()
        }
        .onReceive(timer) { _ in
            if isActive {
                handleTimerTick()
            }
        }
        .onReceive(syncTimer) { _ in
            if isActive {
                syncAudioWithVisuals()
            }
        }
    }
    
    private func startBreathing() {
        isActive = true
        audioManager.start()
        hapticLight.impactOccurred() // Changed from Heavy to Light for a gentler start
        startInhale()
    }
    
    private func startInhale() {
        phase = .inhale
        timeRemaining = 4
        breathScale = 1.0 // Expand
        bgColor = Color(hex: "064e3b") // Brighter/warmer on inhale
        hapticSoft.impactOccurred()
    }
    
    private func startHold() {
        phase = .hold
        timeRemaining = 2
        hapticLight.impactOccurred()
    }
    
    private func startExhale() {
        phase = .exhale
        timeRemaining = 4
        breathScale = 0.3 // Shrink
        bgColor = Color(hex: "020617") // Deep and cool on exhale
        hapticSoft.impactOccurred()
    }
    
    private func handleTimerTick() {
        if timeRemaining > 1 {
            timeRemaining -= 1
            // Subtle haptic every second
            hapticSoft.impactOccurred(intensity: 0.5)
        } else {
            // Transition to next phase
            switch phase {
            case .ready, .exhale:
                startInhale()
            case .inhale:
                startHold()
            case .hold:
                startExhale()
            }
        }
    }
    
    private func syncAudioWithVisuals() {
        // We sync the audio low-pass filter with the visual scale (0.3 to 1.0)

        // To approximate it perfectly without using presentation layer, we can just use our own time calculation.
        // Or we can just calculate it based on timeRemaining and phase.
        
        var audioPhase: Float = 0.0
        
        switch phase {
        case .inhale:
            // timeRemaining goes from 4 to 1. Invert to 0.0 to 1.0
            audioPhase = Float(4 - timeRemaining) / 4.0
        case .hold:
            audioPhase = 1.0
        case .exhale:
            // timeRemaining goes from 4 to 1. Map to 1.0 to 0.0
            audioPhase = Float(timeRemaining) / 4.0
        case .ready:
            audioPhase = 0.0
        }
        
        audioManager.setBreathPhase(audioPhase)
    }
}

#Preview {
    CreativeBreathingView()
        .environmentObject(SleepTabBarVisibility())
}

// MARK: - Helpers
private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
