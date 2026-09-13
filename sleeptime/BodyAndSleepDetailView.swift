import SwiftUI

struct BodyAndSleepDetailView: View {
    @State private var expandedStates: [Bool] = Array(repeating: false, count: 5)
    
    let items = [
        CardItem(
            title: "免疫与抵御力",
            summary: "早早入睡，为什么感冒和身体微恙能明显更快好转",
            mechanism: "在整夜安稳的睡眠中，机体会集中调动**细胞因子**与**免疫T细胞**的防御活力，全力扑灭体内的病原与微小炎症，为免疫系统补充能量。",
            feeling: "喉咙干燥、轻微头晕等不适感明显减轻；体能从深处快速回暖，身体摆脱虚弱无力感，重新变得轻快。"
        ),
        CardItem(
            title: "大脑清明与专注",
            summary: "整夜好眠如何清洗代谢废物，让你次日头脑透亮",
            mechanism: "夜间入睡后，大脑会激活一套微观的清理通道，像冲水一样高效排出白天思考累积的**腺苷**（疲倦物质）与多余代谢垃圾。",
            feeling: "晨起时毫无发木与头重脚轻感。负责自控与决策的**大脑前额叶**恢复活力，不仅注意力能够高度集中，面对刷手机、吃零食等分心诱惑也更有克制力。"
        ),
        CardItem(
            title: "食欲平衡与代谢",
            summary: "睡足时间，如何自然抚平暴食冲动、保持平稳身形",
            mechanism: "睡眠会自然校准饱腹信号（**瘦素**）与饥饿信号的平衡，并重置机体对**胰岛素**的敏感性，让身体重新变回高效率消耗能量的状态。",
            feeling: "白天食欲温和规律，不会突然产生对奶茶、甜品或油炸碳水的猛烈渴望；饭后不容易发困，吃进去的热量也更不易堆积为脂肪。"
        ),
        CardItem(
            title: "舒缓减压与血管养护",
            summary: "准时入睡，给内脏与血管一次真正的减压保养",
            mechanism: "按时入睡后，身体由副交感神经掌管，心率与血压平稳下调，白天紧绷的血管壁得到放松与滋养，全身的隐性炎症指标也随之下降。",
            feeling: "肩颈与后背的酸胀紧绷感消退，心跳平稳踏实；白天应对工作节奏时不易烦躁焦虑，呼吸更加均匀沉稳。"
        ),
        CardItem(
            title: "气色红润与肌肤滋养",
            summary: "为什么说早睡是零成本护肤：夜间屏障自我修护",
            mechanism: "睡眠期间身体会迎来**生长激素**的释放节律，加快表皮细胞的修整，同时血液更顺畅地流向皮肤表层，送去充足的氧气与水分。",
            feeling: "脸部皮肤保水力更好，不易干燥或反常泛油；眼周微循环通畅，黑眼圈悄悄减淡，整个人看起来神采奕奕。"
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("睡眠的自愈力量")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.bottom, 2)
                    
                    Text("好好睡上一觉，是身体最高效的自我调养。看清夜间休息如何悄悄修复你的精力与体魄。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                VStack(spacing: 12) {
                    ForEach(items.indices, id: \.self) { index in
                        ExpandableCard(item: items[index], isExpanded: $expandedStates[index])
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("睡眠与身体")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }
}

struct CardItem {
    let title: String
    let summary: String
    let mechanism: String
    let feeling: String
}

struct ExpandableCard: View {
    let item: CardItem
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Text(item.summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("身体修护机制")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text(LocalizedStringKey(item.mechanism))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("清醒时的直观感受")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text(LocalizedStringKey(item.feeling))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

#Preview {
    NavigationView {
        BodyAndSleepDetailView()
    }
}
