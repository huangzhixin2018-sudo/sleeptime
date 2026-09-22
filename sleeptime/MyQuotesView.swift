import SwiftUI

struct QuoteItem: Identifiable {
    let id = UUID()
    let content: String
    let author: String
    let date: String
}

struct MyQuotesView: View {
    @State private var quotes: [QuoteItem] = [
        QuoteItem(content: "万物皆有裂痕，那是光照进来的地方。", author: "Leonard Cohen", date: "2023.10.15"),
        QuoteItem(content: "生活不是等待风暴过去，而是学会在雨中翩翩起舞。", author: "Vivian Greene", date: "2023.10.12"),
        QuoteItem(content: "你不能把点滴联系起来，只能在回顾时将它们联系起来。所以你必须相信，这些点滴会在你未来的生命里，以某种方式串联起来。", author: "Steve Jobs", date: "2023.09.28")
    ]
    
    @State private var showAddSheet = false

    var body: some View {
        ZStack {
            Color(hex: "f7f9fa").ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("我的语录")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "0f172a"))

                        Text("收藏触动心弦的文字，照亮前行的路。")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color(hex: "64748b"))
                            .lineSpacing(5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    if quotes.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "quote.bubble")
                                .font(.system(size: 48))
                                .foregroundColor(Color(hex: "cbd5e1"))
                            Text("还没有收藏任何语录")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "94a3b8"))
                        }
                        .padding(.top, 100)
                    } else {
                        ForEach(quotes) { quote in
                            QuoteCard(quote: quote)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 120)
                }
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showAddSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                        Text("记录感悟")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color(hex: "0f172a"))
                    .cornerRadius(30)
                    .shadow(color: Color(hex: "0f172a").opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showAddSheet) {
            AddQuoteView { newQuote in
                withAnimation(.spring()) {
                    quotes.insert(newQuote, at: 0)
                }
            }
        }
    }
}

struct QuoteCard: View {
    let quote: QuoteItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "quote.opening")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(hex: "cbd5e1").opacity(0.5))
            
            Text(quote.content)
                .font(.custom("Songti SC", size: 18)) // serif font for elegant look
                .fontWeight(.regular)
                .foregroundColor(Color(hex: "1e293b"))
                .lineSpacing(8)
            
            HStack {
                Text(quote.date)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "94a3b8"))
                
                Spacer()
                
                if !quote.author.isEmpty {
                    Text("—— \(quote.author)")
                        .font(.custom("Songti SC", size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "64748b"))
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
}

struct AddQuoteView: View {
    @Environment(\.dismiss) var dismiss
    @State private var content: String = ""
    @State private var author: String = ""
    var onAdd: (QuoteItem) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(hex: "0f172a"))
                }
                Spacer()
                Text("记录感悟")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "0f172a"))
                Spacer()
                Button(action: { save() }) {
                    Text("保存")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(content.trimmingCharacters(in: .whitespaces).isEmpty ? Color(hex: "94a3b8") : Color(hex: "0f172a"))
                }
                .disabled(content.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Content Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("语录内容")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "64748b"))
                        
                        TextEditor(text: $content)
                            .font(.custom("Songti SC", size: 16))
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "e2e8f0"), lineWidth: 1)
                            )
                    }
                    
                    // Author Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("出处或作者（选填）")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "64748b"))
                        
                        TextField("例如：王尔德", text: $author)
                            .font(.system(size: 16))
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "e2e8f0"), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color(hex: "f7f9fa").ignoresSafeArea())
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func save() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        let dateStr = formatter.string(from: Date())
        
        let newQuote = QuoteItem(content: content, author: author, date: dateStr)
        onAdd(newQuote)
        dismiss()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
    MyQuotesView()
}
