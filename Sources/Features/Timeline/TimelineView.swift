import SwiftUI
import SwiftData

/// タイムライン画面
/// 今日の録音状況、リアルタイム文字起こしを表示
struct TimelineView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<DailyRecord> { record in
            record.date >= Calendar.current.startOfDay(for: Date())
        },
        sort: \DailyRecord.date,
        order: .reverse
    )
    private var todayRecords: [DailyRecord]
    
    @State private var isRecording = false
    
    private var todayRecord: DailyRecord? {
        todayRecords.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Design.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: Design.Spacing.lg) {
                    // Header
                    headerView
                    
                    // Recording Status
                    recordingStatusView
                    
                    // Today's Stats
                    if let record = todayRecord {
                        statsView(record: record)
                    }
                    
                    // Segments List
                    segmentsListView
                    
                    Spacer()
                    
                    // Record Button
                    recordButton
                }
                .padding(Design.Spacing.md)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("CONTEXTLIFE")
                        .font(Design.Typography.headline)
                        .foregroundColor(Design.Colors.primary)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: Design.Spacing.xs) {
                Text(formattedDate)
                    .font(Design.Typography.title)
                    .foregroundColor(Design.Colors.primary)
                
                Text(formattedWeekday)
                    .font(Design.Typography.caption)
                    .foregroundColor(Design.Colors.secondary)
            }
            
            Spacer()
            
            // Recording indicator
            if isRecording {
                HStack(spacing: Design.Spacing.xs) {
                    Circle()
                        .fill(Design.Colors.error)
                        .frame(width: 8, height: 8)
                    Text("REC")
                        .font(Design.Typography.caption)
                        .foregroundColor(Design.Colors.error)
                }
            }
        }
    }
    
    private var recordingStatusView: some View {
        VStack(spacing: Design.Spacing.sm) {
            Text(isRecording ? "Recording..." : "Ready")
                .font(Design.Typography.headline)
                .foregroundColor(isRecording ? Design.Colors.primary : Design.Colors.secondary)
            
            // Waveform placeholder
            HStack(spacing: 2) {
                ForEach(0..<20, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(isRecording ? Design.Colors.primary : Design.Colors.border)
                        .frame(width: 3, height: CGFloat.random(in: 10...40))
                }
            }
            .frame(height: 40)
        }
        .terminalCard()
    }
    
    private func statsView(record: DailyRecord) -> some View {
        HStack(spacing: Design.Spacing.lg) {
            StatItem(
                title: "録音時間",
                value: record.formattedTotalDuration
            )
            
            StatItem(
                title: "セグメント",
                value: "\(record.segments.count)"
            )
            
            StatItem(
                title: "処理済み",
                value: "\(record.processedCount)/\(record.segments.count)"
            )
        }
        .terminalCard()
    }
    
    private var segmentsListView: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            Text("Today's Segments")
                .font(Design.Typography.caption)
                .foregroundColor(Design.Colors.secondary)
            
            if let record = todayRecord, !record.segments.isEmpty {
                ScrollView {
                    LazyVStack(spacing: Design.Spacing.sm) {
                        ForEach(record.segments.sorted { $0.timestamp > $1.timestamp }, id: \.timestamp) { segment in
                            SegmentRow(segment: segment)
                        }
                    }
                }
            } else {
                Text("No recordings yet")
                    .font(Design.Typography.body)
                    .foregroundColor(Design.Colors.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(Design.Spacing.lg)
            }
        }
    }
    
    private var recordButton: some View {
        Button {
            isRecording.toggle()
        } label: {
            HStack {
                Image(systemName: isRecording ? "stop.fill" : "record.circle")
                Text(isRecording ? "STOP" : "START")
            }
            .frame(maxWidth: .infinity)
            .primaryButton()
        }
    }
    
    // MARK: - Helpers
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: Date())
    }
    
    private var formattedWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: Date())
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: Design.Spacing.xs) {
            Text(value)
                .font(Design.Typography.headline)
                .foregroundColor(Design.Colors.primary)
            
            Text(title)
                .font(Design.Typography.small)
                .foregroundColor(Design.Colors.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Segment Row

struct SegmentRow: View {
    let segment: TranscriptionSegment
    
    var body: some View {
        HStack(spacing: Design.Spacing.sm) {
            // Time
            Text(segment.formattedTime)
                .font(Design.Typography.caption)
                .foregroundColor(Design.Colors.secondary)
                .frame(width: 50, alignment: .leading)
            
            // Status icon
            Image(systemName: segment.status.iconName)
                .foregroundColor(statusColor)
                .font(.system(size: 12))
            
            // Transcription preview
            Text(segment.transcriptionPreview)
                .font(Design.Typography.body)
                .foregroundColor(Design.Colors.primary)
                .lineLimit(1)
            
            Spacer()
            
            // Duration
            Text(segment.formattedDuration)
                .font(Design.Typography.small)
                .foregroundColor(Design.Colors.secondary)
        }
        .padding(Design.Spacing.sm)
        .background(Design.Colors.cardBackground)
        .cornerRadius(Design.CornerRadius.sm)
    }
    
    private var statusColor: Color {
        switch segment.status {
        case .pending: return Design.Colors.secondary
        case .completed: return Design.Colors.primary
        case .failed: return Design.Colors.error
        }
    }
}

// MARK: - Preview

#Preview {
    TimelineView()
        .modelContainer(for: [
            DailyRecord.self,
            TranscriptionSegment.self
        ], inMemory: true)
}
