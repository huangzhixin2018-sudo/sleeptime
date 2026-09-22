import SwiftUI

struct SleepDiaryRecord: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let status: String
    let note: String
}

struct SleepStatusDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("sleepDiary.records.v1") private var encodedRecords = "[]"
    @State private var records: [SleepDiaryRecord] = []

    // 状态定义
    let statusOptions = ["梦境", "失眠", "入睡难", "半夜醒"]

    // 表单状态
    @State private var selectedDate = Date()
    @State private var selectedStatus: String? = nil
    @State private var noteText: String = ""
    @FocusState private var isNoteFocused: Bool
    
    var existingRecordOnSelectedDate: Bool {
        records.contains { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var canSave: Bool {
        selectedStatus != nil && !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !existingRecordOnSelectedDate
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 36) {
                
                // 1. 时间选择 (极简)
                HStack {
                    Text("时间")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                    Spacer()
                    DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                        .labelsHidden()
                        .tint(.black)
                }
                .padding(.horizontal, 24)
                
                // 2. 状态选择 (现代方角药丸)
                VStack(alignment: .leading, spacing: 16) {
                    Text("状态")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                    
                    HStack(spacing: 12) {
                        ForEach(statusOptions, id: \.self) { status in
                            Button(action: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    selectedStatus = status
                                }
                            }) {
                                Text(status)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(selectedStatus == status ? .white : .black.opacity(0.8))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(selectedStatus == status ? Color.black : Color(white: 0.96))
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(existingRecordOnSelectedDate)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // 3. 极简编辑框
                VStack(alignment: .leading, spacing: 8) {
                    ZStack(alignment: .topLeading) {
                        if noteText.isEmpty {
                            Text(existingRecordOnSelectedDate ? "这天已经记录过了哦" : "这一刻的想法...")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(Color(white: 0.75))
                                .padding(.top, 12)
                                .padding(.leading, 12)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $noteText)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.black.opacity(0.9))
                            .frame(minHeight: 160)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .focused($isNoteFocused)
                            .disabled(existingRecordOnSelectedDate)
                    }
                    .background(Color(white: 0.98))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
            .padding(.top, 24)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationTitle("睡眠札记")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    saveRecord()
                    dismiss()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(canSave ? .orange : .gray.opacity(0.4))
                .disabled(!canSave)
            }
        }
        .onAppear(perform: loadRecords)
        .onTapGesture {
            isNoteFocused = false
        }
    }
    
    private func loadRecords() {
        guard let data = encodedRecords.data(using: .utf8) else { return }
        records = (try? JSONDecoder().decode([SleepDiaryRecord].self, from: data)) ?? []
    }

    private func saveRecord() {
        guard canSave else { return }
        guard let status = selectedStatus else { return }
        let text = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let newRecord = SleepDiaryRecord(date: selectedDate, status: status, note: text)
        records.insert(newRecord, at: 0)
        
        if let data = try? JSONEncoder().encode(records),
           let value = String(data: data, encoding: .utf8) {
            encodedRecords = value
        }
    }
}

struct SleepStatusDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SleepStatusDetailView()
        }
    }
}
