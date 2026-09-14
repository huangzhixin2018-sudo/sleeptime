import SwiftUI

struct SimpleFishView: View {
    var body: some View {
        Image(systemName: "fish.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(red: 0.4, green: 0.5, blue: 0.8), Color(red: 0.2, green: 0.3, blue: 0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

#Preview {
    SimpleFishView()
        .frame(width: 100, height: 60)
}
