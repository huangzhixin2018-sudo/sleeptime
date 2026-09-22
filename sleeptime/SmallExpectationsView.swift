import SwiftUI

struct ExpectationItem: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let weekday: String
    var isFulfilled: Bool
}

struct SmallExpectationsView: View {
    @State private var items = [
        ExpectationItem(title: "去喝惦记很久的那杯深烘咖啡", date: "10月1日", weekday: "周二", isFulfilled: false),
        ExpectationItem(title: "留一个晚上，看完收藏里的那部电影", date: "9月18日", weekday: "周三", isFulfilled: false),
        ExpectationItem(title: "等秋天的第一件风衣送到家", date: "9月23日", weekday: "周一", isFulfilled: false),
        ExpectationItem(title: "给房间带回一束白色洋桔梗", date: "9月12日", weekday: "周四", isFulfilled: true),
        ExpectationItem(title: "关掉闹钟，安心睡到自然醒", date: "9月15日", weekday: "周日", isFulfilled: true)
    ]

    @State private var showFulfilled = false
    @State private var showAddSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "f7f9fa").ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("小期待")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "0f172a"))

                    Text("给平常的日子，留几件值得盼望的小事。")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(hex: "64748b"))
                        .lineSpacing(5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)

                // Custom Tabs
                HStack(spacing: 12) {
                    TabButton(title: "期待中", isActive: !showFulfilled) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showFulfilled = false
                        }
                    }

                    TabButton(title: "已实现", isActive: showFulfilled) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showFulfilled = true
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // List
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        let filteredItems = items.filter { $0.isFulfilled == showFulfilled }

                        if filteredItems.isEmpty {
                            Text(showFulfilled ? "实现过的小期待会留在这里" : "写下一件最近想做的小事吧")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "94a3b8"))
                                .padding(.top, 60)
                        } else {
                            ForEach(filteredItems) { item in
                                TicketCard(item: item) {
                                    toggleFulfillment(for: item)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }

            // Floating Action Button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                showAddSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                    Text("写下期待")
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .sheet(isPresented: $showAddSheet) {
            AddExpectationView { newItem in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    items.insert(newItem, at: 0)
                }
            }
        }
    }

    private func toggleFulfillment(for item: ExpectationItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()

            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                items[index].isFulfilled.toggle()
            }
        }
    }
}

// MARK: - Components

struct AddExpectationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""
    @State private var selectedDate = Date()
    var onAdd: (ExpectationItem) -> Void

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
                Text("写下新期待")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "0f172a"))
                Spacer()
                Button(action: { save() }) {
                    Text("保存")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(title.trimmingCharacters(in: .whitespaces).isEmpty ? Color(hex: "94a3b8") : Color(hex: "0f172a"))
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Title Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("期待的内容")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "64748b"))
                        
                        TextField("写下一件最近想做的小事...", text: $title)
                            .font(.system(size: 16))
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "e2e8f0"), lineWidth: 1)
                            )
                    }
                    
                    // Date Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("计划时间")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "64748b"))
                        
                        DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "e2e8f0"), lineWidth: 1)
                            )
                            .tint(Color(hex: "0f172a"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color(hex: "f7f9fa").ignoresSafeArea())
    }
    
    private func save() {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        formatter.locale = Locale(identifier: "zh_CN")
        let dateStr = formatter.string(from: selectedDate)
        
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE"
        weekdayFormatter.locale = Locale(identifier: "zh_CN")
        var weekdayStr = weekdayFormatter.string(from: selectedDate)
        weekdayStr = weekdayStr.replacingOccurrences(of: "星期", with: "周")
        
        let newItem = ExpectationItem(title: title, date: dateStr, weekday: weekdayStr, isFulfilled: false)
        onAdd(newItem)
        dismiss()
    }
}

// MARK: - Components

struct TabButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isActive ? .bold : .medium))
                .foregroundColor(isActive ? Color(hex: "0f172a") : Color(hex: "64748b"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isActive ? Color.white : Color.clear)
                .cornerRadius(20)
                .shadow(color: isActive ? Color.black.opacity(0.04) : Color.clear, radius: 4, x: 0, y: 2)
        }
    }
}

struct TicketCard: View {
    let item: ExpectationItem
    let action: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Left Section (Date)
            VStack(spacing: 5) {
                Text(item.weekday)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(item.isFulfilled ? Color(hex: "94a3b8") : Color(hex: "1e293b"))

                Text(item.date)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(hex: "64748b").opacity(item.isFulfilled ? 0.7 : 1))
                    .monospacedDigit()
            }
            .frame(width: 92)
            .padding(.vertical, 24)

            // Dashed Divider
            Line()
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                .frame(width: 1)
                .foregroundColor(Color(hex: "e2e8f0"))

            // Right Section (Content)
            HStack {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(item.isFulfilled ? Color(hex: "94a3b8") : Color(hex: "1e293b"))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 12)

                // Action Button / Stamp
                Button(action: action) {
                    if item.isFulfilled {
                        // Stamp effect
                        VStack(spacing: 2) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 24))
                            Text("已实现")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "10b981")) // Emerald green
                        .rotationEffect(.degrees(-8))
                        .opacity(0.8)
                    } else {
                        // Checkbox
                        Circle()
                            .strokeBorder(Color(hex: "cbd5e1"), lineWidth: 2)
                            .background(Circle().fill(Color.clear))
                            .frame(width: 28, height: 28)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity, minHeight: 124)
        .background(Color.white)
        .clipShape(TicketShape())
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Shapes

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        return path
    }
}

struct TicketShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = 16
        let holeRadius: CGFloat = 8
        let holeX: CGFloat = 92 // Matches the width of the left section

        // Start top-left
        path.move(to: CGPoint(x: cornerRadius, y: 0))

        // Top edge and top hole
        path.addLine(to: CGPoint(x: holeX - holeRadius, y: 0))
        path.addArc(center: CGPoint(x: holeX, y: 0), radius: holeRadius, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))

        // Top-right corner
        path.addArc(center: CGPoint(x: rect.width - cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)

        // Right edge
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))

        // Bottom-right corner
        path.addArc(center: CGPoint(x: rect.width - cornerRadius, y: rect.height - cornerRadius), radius: cornerRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)

        // Bottom edge and bottom hole
        path.addLine(to: CGPoint(x: holeX + holeRadius, y: rect.height))
        path.addArc(center: CGPoint(x: holeX, y: rect.height), radius: holeRadius, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: true)
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))

        // Bottom-left corner
        path.addArc(center: CGPoint(x: cornerRadius, y: rect.height - cornerRadius), radius: cornerRadius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)

        // Left edge
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))

        // Top-left corner
        path.addArc(center: CGPoint(x: cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)

        path.closeSubpath()
        return path
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
    SmallExpectationsView()
}
