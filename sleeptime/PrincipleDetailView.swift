//
//  PrincipleDetailView.swift
//  sleeptime
//

import SwiftUI

struct PrincipleDetailView: View {
    let title: String
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header (No Subtitle)
                VStack(alignment: .leading, spacing: 8) {
                    Text("# \(title)")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Card 1: 轻盈的暗色风格 (Soft Dark Aesthetic)
                PrincipleCardView(
                    quote: "一天的成功，\n奠定在前一晚的决定中。",
                    author: "Night Routine",
                    theme: .dark
                )
                
                // Card 2: 典雅留白风格 (Light Minimalist)
                PrincipleCardView(
                    quote: "不要让未来的自己，\n为现在的慵懒买单。",
                    author: "Future Self",
                    theme: .light
                )
                
                Spacer()
            }
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.99).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate enum CardTheme {
    case dark
    case light
}

fileprivate struct PrincipleCardView: View {
    let quote: String
    let author: String
    let theme: CardTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 使用优雅的双引号文字替代之前的逗号图标
            Text("“")
                .font(.system(size: 40, weight: .bold, design: .serif))
                .foregroundColor(theme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08))
                .offset(x: -4, y: 10)
            
            Text(quote)
                .font(.system(size: 18, weight: .medium, design: .serif))
                .foregroundColor(theme == .dark ? .white : .primary)
                .lineSpacing(8)
            
            HStack {
                Spacer()
                Text("— " + author)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(theme == .dark ? Color.white.opacity(0.6) : Color.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                if theme == .dark {
                    LinearGradient(
                        colors: [Color(red: 0.15, green: 0.16, blue: 0.18), Color(red: 0.1, green: 0.1, blue: 0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    Color.white
                }
            }
        )
        .cornerRadius(20)
        // 降低厚重感：减小 shadow 的 radius 和 opacity
        .shadow(color: theme == .dark ? Color.black.opacity(0.1) : Color.black.opacity(0.02), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 24)
    }
}

struct PrincipleDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrincipleDetailView(title: "提前计划")
        }
    }
}
