import SwiftUI

// MARK: - Models
struct MedItem: Identifiable {
    let id = UUID()
    let tag: String
    let title: String
    let desc: String
    let duration: String
}

struct PodItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let sub: String
}

struct QuoteItem: Identifiable {
    let id = UUID()
    let text: String
    let author: String
}

struct SoundLibItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let meta: String
}

enum LibraryCategory: Int, CaseIterable {
    case meditation = 0
    case podcast = 1
    case quotes = 2
    case sounds = 3
    
    var title: String {
        switch self {
        case .meditation: return "冥想"
        case .podcast: return "播客"
        case .quotes: return "句集"
        case .sounds: return "声音"
        }
    }
}

// MARK: - Store
let medData = [
    MedItem(tag: "0.1Hz 呼吸坡度", title: "晨间专注 · 额叶注意重塑", desc: "利用 4-2-4 经典节律，降低早晨皮质醇激增带来的无序杂念。", duration: "5 分钟"),
    MedItem(tag: "情绪解离", title: "中立观察 · 思绪浮云过滤", desc: "不参与任何升起的念头判定，视脑海意识流动为中立数据流。", duration: "8 分钟")
]

let podData = [
    PodItem(icon: "🎙️", title: "睡眠如何深度清洗大脑代谢毒素", sub: "Ep.42 神经科学 · 28 分钟"),
    PodItem(icon: "🧠", title: "从前额叶到多巴胺：自控力的物理学", sub: "Ep.19 认知工程 · 21 分钟"),
    PodItem(icon: "⚡️", title: "反内耗算法：构建自己的认知防火墙", sub: "Ep.08 现代斯多葛 · 34 分钟")
]

let quoteData = [
    QuoteItem(text: "“你随时都可以隐退到自己的内心深处。没有任何地方比你自己的灵魂更宁静、更无牵无挂。”", author: "马可·奥勒留 ·《沉思录》"),
    QuoteItem(text: "“大多数人像一片落叶，在空中翻滚飘摇，最后落在地上。但有些人像天上的星星，依既定轨道运行，无风可吹动。”", author: "赫尔曼·黑塞 ·《悉达多》")
]

let soundData = [
    SoundLibItem(icon: "〰️", title: "Alpha 10Hz", meta: "双耳相干波"),
    SoundLibItem(icon: "🌧️", title: "粉红微风", meta: "400Hz 低通"),
    SoundLibItem(icon: "🌿", title: "森林微雨", meta: "自然白噪"),
    SoundLibItem(icon: "🔔", title: "颂钵低频", meta: "136.1Hz 谐振")
]

// MARK: - Main View
struct SoundLibraryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: LibraryCategory = .meditation
    @State private var shelfSet: Set<UUID> = []
    
    @State private var showingShelfSheet = false
    @State private var pendingItemId: UUID? = nil
    @State private var pendingItemTitle: String = ""
    
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // 背景色改为白色
    private let bgColor = Color(red: 248/255, green: 248/255, blue: 250/255)
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Header (代替 Navigation Bar)
                HStack(alignment: .bottom) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .background(bgColor.opacity(0.88).ignoresSafeArea())
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Title Area
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CURATED SPACE")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color.gray)
                                    .tracking(1.2)
                                Text("资源库")
                                    .font(.system(size: 29, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Button(action: {
                                // Shelf Action
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color.pink)
                                    Text("书架 (\(shelfSet.count))")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                                .overlay(Capsule().stroke(Color.gray.opacity(0.1), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                        
                        // Segmented Control
                        HStack(spacing: 0) {
                            ForEach(LibraryCategory.allCases, id: \.self) { category in
                                Text(category.title)
                                    .font(.system(size: 13, weight: selectedCategory == category ? .semibold : .medium))
                                    .foregroundColor(selectedCategory == category ? .white : .gray)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 33)
                                    .background(
                                        ZStack {
                                            if selectedCategory == category {
                                                Capsule()
                                                    .fill(Color.blue)
                                                    .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                                                    .matchedGeometryEffect(id: "SEGMENT", in: animation)
                                            }
                                        }
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedCategory = category
                                        }
                                    }
                            }
                        }
                        .padding(3)
                        .background(Color.gray.opacity(0.08))
                        .clipShape(Capsule())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        
                        // Content Cards
                        VStack(spacing: 12) {
                            switch selectedCategory {
                            case .meditation:
                                ForEach(medData) { item in
                                    MeditationCard(item: item, isFav: shelfSet.contains(item.id)) {
                                        toggleBookmark(id: item.id, title: item.title)
                                    }
                                }
                            case .podcast:
                                ForEach(podData) { item in
                                    PodcastCard(item: item, isFav: shelfSet.contains(item.id)) {
                                        toggleBookmark(id: item.id, title: item.title)
                                    }
                                }
                            case .quotes:
                                ForEach(quoteData) { item in
                                    QuoteCard(item: item, isFav: shelfSet.contains(item.id)) {
                                        toggleBookmark(id: item.id, title: item.author)
                                    }
                                }
                            case .sounds:
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                    ForEach(soundData) { item in
                                        SoundItemCard(item: item, isFav: shelfSet.contains(item.id)) {
                                            toggleBookmark(id: item.id, title: item.title)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            
            // Toast
            if showToast {
                Text(toastMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.88))
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 60)
                    .zIndex(100)
            }
        }
        .background(bgColor.ignoresSafeArea())
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showingShelfSheet) {
            ShelfSelectionSheet(
                targetName: pendingItemTitle,
                onConfirm: {
                    if let id = pendingItemId {
                        shelfSet.insert(id)
                        triggerToast("已存入书架")
                    }
                    showingShelfSheet = false
                }
            )
        }
    }
    
    @Namespace private var animation
    
    private func toggleBookmark(id: UUID, title: String) {
        if shelfSet.contains(id) {
            shelfSet.remove(id)
            triggerToast("已从书架移出")
        } else {
            pendingItemId = id
            pendingItemTitle = title
            showingShelfSheet = true
        }
    }
    
    private func triggerToast(_ msg: String) {
        toastMessage = msg
        withAnimation(.spring()) { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.spring()) { showToast = false }
        }
    }
}

// MARK: - Cards
struct HeartButton: View {
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isActive ? "heart.fill" : "heart")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isActive ? .pink : .gray)
                .frame(width: 32, height: 32)
                .background(Color.gray.opacity(0.08))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MeditationCard: View {
    let item: MedItem
    let isFav: Bool
    let onFav: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(item.tag)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(6)
                Spacer()
                HeartButton(isActive: isFav, action: onFav)
            }
            .padding(.bottom, 12)
            
            Text(item.title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.primary)
                .padding(.bottom, 6)
            
            Text(item.desc)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .padding(.bottom, 16)
            
            HStack {
                Text(item.duration)
                Spacer()
                Text("每日推荐")
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
            }
            .font(.system(size: 12))
            .foregroundColor(.gray)
            .padding(.top, 12)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.1)), alignment: .top)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.05), lineWidth: 1))
    }
}

struct PodcastCard: View {
    let item: PodItem
    let isFav: Bool
    let onFav: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Text(item.icon)
                .font(.system(size: 20))
                .frame(width: 42, height: 42)
                .background(Color(white: 0.95))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(item.sub)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
            HeartButton(isActive: isFav, action: onFav)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.gray.opacity(0.05), lineWidth: 1))
    }
}

struct QuoteCard: View {
    let item: QuoteItem
    let isFav: Bool
    let onFav: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("APHORISM")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray.opacity(0.6))
                    .tracking(1.0)
                Spacer()
                HeartButton(isActive: isFav, action: onFav)
            }
            .padding(.bottom, 8)
            
            Text(item.text)
                .font(.system(size: 15))
                .lineSpacing(6)
                .foregroundColor(.primary)
                .padding(.bottom, 14)
                .padding(.trailing, 28)
            
            HStack {
                Text(item.author)
                Spacer()
                Text("意念定格")
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.05), lineWidth: 1))
    }
}

struct SoundItemCard: View {
    let item: SoundLibItem
    let isFav: Bool
    let onFav: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(item.icon)
                    .font(.system(size: 20))
                Spacer()
                HeartButton(isActive: isFav, action: onFav)
            }
            Spacer(minLength: 16)
            Text(item.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
                .padding(.bottom, 2)
            Text(item.meta)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(height: 128)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.gray.opacity(0.05), lineWidth: 1))
    }
}

// MARK: - Action Sheet
struct ShelfSelectionSheet: View {
    let targetName: String
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFolder = 0
    
    let folders = [
        ("☀️", "晨间定志库"),
        ("⚡️", "深度心流装备"),
        ("🌙", "入夜意识熄灯")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(white: 0.9))
                .frame(width: 36, height: 4)
                .padding(.top, 16)
                .padding(.bottom, 16)
            
            Text("加入我的书架")
                .font(.system(size: 16, weight: .bold))
                .padding(.bottom, 4)
            
            Text("存放 · \(targetName)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.bottom, 24)
            
            VStack(spacing: 8) {
                ForEach(0..<folders.count, id: \.self) { index in
                    let isSelected = (selectedFolder == index)
                    HStack(spacing: 10) {
                        Text(folders[index].0)
                        Text(folders[index].1)
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                        ZStack {
                            Circle()
                                .stroke(isSelected ? Color.blue : Color(white: 0.8), lineWidth: 1.5)
                                .frame(width: 18, height: 18)
                            if isSelected {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 18, height: 18)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(isSelected ? Color.blue.opacity(0.06) : Color(red: 248/255, green: 248/255, blue: 250/255))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.blue.opacity(0.15) : Color.clear, lineWidth: 1)
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFolder = index
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            
            Button(action: onConfirm) {
                Text("确定加入")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.black)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            
            Spacer(minLength: 0)
        }
        .presentationDetents([.fraction(0.55)])
    }
}

#Preview {
    SoundLibraryDetailView()
}
