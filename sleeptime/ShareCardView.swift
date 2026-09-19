import SwiftUI

struct ShareCardView: View {
    let date: Date
    let isEarlySleep: Bool
    let bedtimeMinutes: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航行
            HStack(alignment: .center) {
                HStack(spacing: 12) {
                    Text(dayString)
                        .font(.system(size: 56, weight: .heavy))
                        .foregroundColor(Color(hex: "0d0d0d"))
                        .tracking(-2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(yearMonthString)
                            .font(.system(size: 14.5, weight: .bold))
                            .foregroundColor(Color(hex: "1a1a1a"))
                        Text(weekdayString)
                            .font(.system(size: 14.5, weight: .bold))
                            .foregroundColor(Color(hex: "1a1a1a"))
                    }
                }
                
                Spacer()
                
                Text(isEarlySleep ? "早睡" : "熬夜")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(isEarlySleep ? Color(hex: "3b66cf") : Color(red: 0.72, green: 0.29, blue: 0.30))
                    .tracking(2)
            }
            .padding(.bottom, 22)
            
            // 极简时钟
            ClockFaceView(minutes: bedtimeMinutes)
                .padding(.bottom, 22)
            
            // 入睡时间数码区
            VStack(spacing: 4) {
                Text("入睡时间")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "717173"))
                    .tracking(1.5)
                
                Text(timeString)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "121212"))
                    .tracking(1.5)
            }
            .padding(.bottom, 18)
            
            // 分割线
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color(hex: "111111"))
                .frame(width: 28, height: 3)
                .padding(.bottom, 16)
            
            // 哲例文案区
            Text("人生真正的丰盛，并不在于拥有多少，而在于是否感受过生活本身。")
                .font(.system(size: 15.5, weight: .semibold, design: .serif))
                .foregroundColor(Color(hex: "2b2b2e"))
                .lineSpacing(6)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
                .padding(.bottom, 24)
            
            // 底部品牌信息与二维码模块
            VStack(spacing: 0) {
                Divider()
                    .background(Color(hex: "eaeaea"))
                
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("此刻早睡")
                            .font(.system(size: 19, weight: .heavy))
                            .foregroundColor(.black)
                            .tracking(-0.3)
                        Text("规律作息，养成早睡习惯")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "666666"))
                            .tracking(0.2)
                    }
                    
                    Spacer()
                    
                    // 占位二维码容器
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "e7e7e7"), lineWidth: 1)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                        
                        Image(systemName: "qrcode")
                            .resizable()
                            .padding(6)
                            .foregroundColor(.black)
                    }
                    .frame(width: 56, height: 56)
                }
                .padding(.top, 18)
            }
        }
        .padding(EdgeInsets(top: 34, leading: 28, bottom: 26, trailing: 28))
        .frame(width: 380)
        .background(Color.white)
        .cornerRadius(32)
        // Note: For image rendering, shadows on the very edge might get clipped unless padded.
    }
    
    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var yearMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }
    
    private var weekdayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private var timeString: String {
        String(format: "%02d:%02d", (bedtimeMinutes / 60) % 24, bedtimeMinutes % 60)
    }
}

struct ClockFaceView: View {
    let minutes: Int
    
    var body: some View {
        ZStack {
            // 表盘外框
            Circle()
                .strokeBorder(Color(hex: "141414"), lineWidth: 8)
                .background(Circle().fill(Color.white))
                .frame(width: 210, height: 210)
            
            // 四个点滴
            ClockDot(color: Color(hex: "f7a831")).offset(y: -93) // 12点
            ClockDot(color: Color(hex: "6575b6")).offset(x: 93)  // 3点
            ClockDot(color: Color(hex: "e03f38")).offset(y: 93)  // 6点
            ClockDot(color: Color(hex: "72cfb0")).offset(x: -93) // 9点
            
            // 刻度数字
            Group {
                ClockNumber(num: "10").offset(x: -65, y: -55)
                ClockNumber(num: "11").offset(x: -35, y: -73)
                ClockNumber(num: "1").offset(x: 35, y: -73)
                ClockNumber(num: "2").offset(x: 65, y: -55)
                ClockNumber(num: "4").offset(x: 65, y: 55)
                ClockNumber(num: "5").offset(x: 35, y: 73)
                ClockNumber(num: "7").offset(x: -35, y: 73)
                ClockNumber(num: "8").offset(x: -65, y: 55)
            }
            
            // 指针
            ZStack {
                // 时针
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: "f6aa35"))
                    .frame(width: 12, height: 44)
                    .offset(y: -16) // 指针重心便宜
                    .rotationEffect(Angle(degrees: hourAngle))
                
                // 绿针配重尾部
                Circle()
                    .fill(Color(hex: "36b896"))
                    .frame(width: 14, height: 14)
                    .offset(y: 20)
                    .rotationEffect(Angle(degrees: minuteAngle))
                
                // 分针
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "36b896"))
                    .frame(width: 7, height: 68)
                    .offset(y: -30)
                    .rotationEffect(Angle(degrees: minuteAngle))
                
                // 中心圆帽
                Circle()
                    .fill(Color(hex: "181818"))
                    .frame(width: 24, height: 24)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                
                // 中心小绿点
                Circle()
                    .fill(Color(hex: "49c4a4"))
                    .frame(width: 5, height: 5)
            }
        }
    }
    
    private var hourAngle: Double {
        let hour = Double((minutes / 60) % 12)
        let minute = Double(minutes % 60)
        return (hour + minute / 60.0) * 30.0
    }
    
    private var minuteAngle: Double {
        let minute = Double(minutes % 60)
        return minute * 6.0
    }
}

struct ClockDot: View {
    let color: Color
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
    }
}

struct ClockNumber: View {
    let num: String
    var body: some View {
        Text(num)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(Color(hex: "1a1a1a"))
    }
}



// Helper for Hex Colors
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
