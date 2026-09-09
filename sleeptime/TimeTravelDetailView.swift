//
//  TimeTravelDetailView.swift
//  sleeptime
//

import SwiftUI

struct TimeTravelDetailView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                Spacer().frame(height: 24)
                
                // 内容保持空白，后续开发
                
                Spacer()
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("时间穿梭")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TimeTravelDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TimeTravelDetailView()
        }
    }
}
