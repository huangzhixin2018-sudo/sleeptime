//
//  EmotionDetailView.swift
//  sleeptime
//

import SwiftUI

struct EmotionDetailView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                Spacer().frame(height: 24)
                
                // 内容保持空白，后续开发
                
                Spacer()
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("情绪")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EmotionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EmotionDetailView()
        }
    }
}
