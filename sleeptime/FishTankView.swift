import SwiftUI
import Combine
import QuartzCore


struct FishTier {
    let id: Int
    let days: Int
    let name: String
    let englishName: String
    let desc: String
    let size: CGFloat
    let speed: Double
    let color: Color
}

let FISH_TIERS = [
    FishTier(id: 0, days: 1, name: "小鱼干", englishName: "TINY MINNOW", desc: "刚起步的单日早睡", size: 24, speed: 0.2, color: Color(red: 156/255, green: 163/255, blue: 175/255)),
    FishTier(id: 1, days: 2, name: "小鱼", englishName: "LITTLE FIN", desc: "初步连续的轻快起步", size: 28, speed: 0.6, color: Color(red: 100/255, green: 116/255, blue: 139/255)),
    FishTier(id: 2, days: 3, name: "鱼苗", englishName: "BLUE FRY", desc: "初具成形的小节奏", size: 34, speed: 0.7, color: Color(red: 59/255, green: 130/255, blue: 246/255)),
    FishTier(id: 3, days: 4, name: "幼鱼", englishName: "YOUNG FIN", desc: "逐步稳定的作息骨架", size: 42, speed: 0.5, color: Color(red: 37/255, green: 99/255, blue: 235/255)),
    FishTier(id: 4, days: 5, name: "青鱼", englishName: "JADE SWIMMER", desc: "规律已深入骨髓", size: 50, speed: 0.45, color: Color(red: 15/255, green: 118/255, blue: 110/255)),
    FishTier(id: 5, days: 6, name: "大鱼", englishName: "DEEPWATER", desc: "完成稳定深度作息", size: 68, speed: 0.35, color: Color(red: 30/255, green: 27/255, blue: 75/255))
]

struct FishNode: Identifiable {
    let id = UUID()
    let tier: FishTier
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
}

class FishTankViewModel: ObservableObject {
    @Published var counts: [Int] = [0, 0, 0, 0, 0, 0]
    @Published var totalCount: Int = 0
    @Published var toastMessage: String? = nil
    
    var fishList: [FishNode] = []
    var tankSize: CGSize = CGSize(width: 300, height: 300)
    
    private var displayLink: CADisplayLink?
    
    func startEngine() {
        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(tick))
            displayLink?.add(to: .main, forMode: .common)
            
            // 图鉴原型阶段默认展示六类鱼，每类两条。
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if self.fishList.isEmpty {
                    for tierIndex in FISH_TIERS.indices {
                        self.addFish(tierIndex: tierIndex, showsToast: false)
                        self.addFish(tierIndex: tierIndex, showsToast: false)
                    }
                }
            }
        }
    }
    
    func stopEngine() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    func addFish(tierIndex: Int, showsToast: Bool = true) {
        let tier = FISH_TIERS[tierIndex]
        counts[tierIndex] += 1
        totalCount += 1
        
        let safeW = max(tankSize.width - 80, 20)
        let safeH = max(tankSize.height - 40, 20)
        
        let vx = (Bool.random() ? 1.0 : -1.0) * tier.speed
        let vy = (Double.random(in: 0...1) - 0.5) * 0.2
        
        let node = FishNode(
            tier: tier,
            x: Double.random(in: 20...Double(safeW)),
            y: Double.random(in: 20...Double(safeH)),
            vx: vx,
            vy: vy
        )
        fishList.append(node)
        
        if showsToast {
            showToast("已存入 1 尾「\(tier.name)」")
        }
    }
    
    private var toastTimer: Timer?
    func showToast(_ msg: String) {
        toastMessage = msg
        toastTimer?.invalidate()
        toastTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            self.toastMessage = nil
        }
    }
    
    @objc private func tick() {
        guard tankSize.width > 0 else { return }
        let w = Double(tankSize.width)
        let h = Double(tankSize.height)
        
        var needsRedraw = false
        
        for i in 0..<fishList.count {
            fishList[i].x += fishList[i].vx
            fishList[i].y += fishList[i].vy
            
            let fishW = Double(fishList[i].tier.size)
            
            if fishList[i].x < 10 {
                fishList[i].x = 10
                fishList[i].vx = abs(fishList[i].vx)
            } else if fishList[i].x > w - fishW - 10 {
                fishList[i].x = w - fishW - 10
                fishList[i].vx = -abs(fishList[i].vx)
            }
            
            if fishList[i].y < 10 {
                fishList[i].y = 10
                fishList[i].vy = abs(fishList[i].vy)
            } else if fishList[i].y > h - 30 {
                fishList[i].y = h - 30
                fishList[i].vy = -abs(fishList[i].vy)
            }
            
            fishList[i].vy += (Double.random(in: 0...1) - 0.5) * 0.04
            fishList[i].vy = max(-0.4, min(0.4, fishList[i].vy))
            needsRedraw = true
        }
        
        if needsRedraw {
            objectWillChange.send()
        }
    }
}

struct FishTankView: View {
    @ObservedObject var vm: FishTankViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            
            // Header
            HStack(alignment: .lastTextBaseline) {
                Text("早睡鱼群")
                    .font(.system(size: 22, weight: .bold))
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("已收集")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Text("\(vm.totalCount)")
                        .font(.custom("AvenirNextCondensed-Heavy", size: 26))
                        .foregroundColor(.primary)
                    
                    Text("条")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
            
            // Aquarium
            ZStack {
                Color(red: 248/255, green: 249/255, blue: 250/255)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                if vm.totalCount == 0 {
                    VStack(spacing: 6) {
                        Text("暂无早睡沉淀")
                            .font(.system(size: 13))
                        Text("完成一轮作息连续即可游入鱼缸")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.secondary)
                }
                
                Canvas { context, size in
                    vm.tankSize = size
                    for fish in vm.fishList {
                        if let symbol = context.resolveSymbol(id: fish.tier.id) {
                            var ctx = context
                            ctx.translateBy(x: fish.x + fish.tier.size/2, y: fish.y + fish.tier.size/2)
                            if fish.vx < 0 {
                                ctx.scaleBy(x: -1, y: 1)
                            }
                            ctx.draw(symbol, at: .zero)
                        }
                    }
                } symbols: {
                    ForEach(FISH_TIERS, id: \.id) { tier in
                        Image("custom_fish")
                            .resizable()
                            .scaledToFit()
                            .frame(width: tier.size, height: tier.size)
                            .tag(tier.id)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                // Toast
                if let msg = vm.toastMessage {
                    VStack {
                        Spacer()
                        Text(msg)
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.8).clipShape(Capsule()))
                            .padding(.bottom, 12)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .frame(height: 320)
            .animation(.easeInOut, value: vm.toastMessage)
            
            // Bento Grid
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    BentoCell(tier: FISH_TIERS[5], count: vm.counts[5])
                    BentoCell(tier: FISH_TIERS[4], count: vm.counts[4])
                    BentoCell(tier: FISH_TIERS[3], count: vm.counts[3])
                }
                GridRow {
                    BentoCell(tier: FISH_TIERS[2], count: vm.counts[2])
                    BentoCell(tier: FISH_TIERS[1], count: vm.counts[1])
                    BentoCell(tier: FISH_TIERS[0], count: vm.counts[0])
                }
            }
            
            
        }
        .onAppear {
            vm.startEngine()
        }
        .onDisappear {
            vm.stopEngine()
        }
    }
}

struct BentoCell: View {
    let tier: FishTier
    let count: Int
    
    var body: some View {
        VStack(spacing: 6) {
            Text("\(tier.name) (\(tier.days)d)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                
            Text("\(count)")
                .font(.custom("AvenirNextCondensed-Bold", size: 30))
                .foregroundColor(count > 0 ? tier.color : Color.gray.opacity(0.4))
                .padding(.top, 4)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }
}
