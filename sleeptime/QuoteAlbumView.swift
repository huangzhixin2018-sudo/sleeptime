import SwiftUI

struct AlbumQuote {
    let id = UUID()
    let chinese: String
    let english: String
    let author: String
}

struct QuoteAlbumView: View {
    let quotes: [AlbumQuote] = [
        AlbumQuote(
            chinese: "生活就像骑自行车。要想保持平衡，就必须不断向前。",
            english: "Life is like riding a bicycle. To keep your balance you must keep moving.",
            author: "阿尔伯特·爱因斯坦 (Albert Einstein)"
        ),
        AlbumQuote(
            chinese: "希望是本无所谓有，无所谓无的。这正如地上的路；其实地上本没有路，走的人多了，也便成了路。",
            english: "Hope cannot be said to exist, nor can it be said not to exist. It is just like roads across the earth. For actually the earth had no roads to begin with, but when many men pass one way, a road is made.",
            author: "鲁迅 (Lu Xun)"
        ),
        AlbumQuote(
            chinese: "不要试图成为一个成功的人，而要成为一个有价值的人。",
            english: "Try not to become a man of success, but rather try to become a man of value.",
            author: "阿尔伯特·爱因斯坦 (Albert Einstein)"
        ),
        AlbumQuote(
            chinese: "认识自己的无知是认识世界的最可靠的方法。",
            english: "To know that you do not know is the best way to know the world.",
            author: "米歇尔·德·蒙田 (Michel de Montaigne)"
        ),
        AlbumQuote(
            chinese: "真正高宏之人，必能造就于艰难绝境之中。",
            english: "Great men are forged in fire. It is the privilege of absurdity to which no living creature is subject, but man only.",
            author: "列夫·托尔斯泰 (Leo Tolstoy)"
        )
    ]
    
    @State private var currentIndex = 0
    @EnvironmentObject private var tabBarVisibility: SleepTabBarVisibility
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "0f172a").ignoresSafeArea() // Dark immersive background
            
            TabView(selection: $currentIndex) {
                ForEach(0..<quotes.count, id: \.self) { index in
                    QuoteAlbumPage(quote: quotes[index])
                    .tag(index)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        // Make navigation bar text white since background is dark
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color(hex: "0f172a"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            tabBarVisibility.isHidden = true
        }
        .onDisappear {
            tabBarVisibility.isHidden = false
        }
    }
}

private struct QuoteAlbumPage: View {
    let quote: AlbumQuote

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                quoteText(minimumHeight: geometry.size.height - 120)
                author
            }
        }
    }

    private func quoteText(minimumHeight: CGFloat) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 40) {
                Text(quote.chinese)
                    .font(.custom("Songti SC", size: 28))
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .lineSpacing(12)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                Text(quote.english)
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .lineSpacing(6)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.vertical, 40)
            .frame(minHeight: minimumHeight)
        }
    }

    private var author: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 1)

            Text(quote.author)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.8))
        }
        .frame(height: 80)
        .padding(.bottom, 40)
    }
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

#Preview {
    QuoteAlbumView()
        .environmentObject(SleepTabBarVisibility())
}
