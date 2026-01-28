import SwiftUI
import SwiftData

/// 履歴画面
/// 過去の録音データを日付別に表示
struct HistoryView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyRecord.date, order: .reverse)
    private var records: [DailyRecord]
    
    @State private var selectedRecord: DailyRecord?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Design.Colors.background
                    .ignoresSafeArea()
                
                if records.isEmpty {
                    emptyStateView
                } else {
                    recordsListView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("HISTORY")
                        .font(Design.Typography.headline)
                        .foregroundColor(Design.Colors.primary)
                }
            }
            .sheet(item: $selectedRecord) { record in
                DailyDetailView(record: record)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: Design.Spacing.md) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundColor(Design.Colors.secondary)
            
            Text("No History")
                .font(Design.Typography.headline)
                .foregroundColor(Design.Colors.secondary)
            
            Text("Start recording to see your history here")
                .font(Design.Typography.caption)
                .foregroundColor(Design.Colors.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Design.Spacing.xl)
    }
    
    private var recordsListView: some View {
        ScrollView {
            LazyVStack(spacing: Design.Spacing.sm) {
                ForEach(records, id: \.date) { record in
                    DailyRecordRow(record: record)
                        .onTapGesture {
                            selectedRecord = record
                        }
                }
            }
            .padding(Design.Spacing.md)
        }
    }
}

// MARK: - Daily Record Row

struct DailyRecordRow: View {
    let record: DailyRecord
    
    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            // Date
            VStack(alignment: .leading, spacing: Design.Spacing.xs) {
                Text(record.formattedDate)
                    .font(Design.Typography.headline)
                    .foregroundColor(Design.Colors.primary)
                
                Text("\(record.segments.count) segments")
                    .font(Design.Typography.small)
                    .foregroundColor(Design.Colors.secondary)
            }
            
            Spacer()
            
            // Duration
            VStack(alignment: .trailing, spacing: Design.Spacing.xs) {
                Text(record.formattedTotalDuration)
                    .font(Design.Typography.body)
                    .foregroundColor(Design.Colors.primary)
                
                // Progress
                HStack(spacing: Design.Spacing.xs) {
                    Circle()
                        .fill(record.isFullyProcessed ? Design.Colors.primary : Design.Colors.warning)
                        .frame(width: 6, height: 6)
                    
                    Text(record.isFullyProcessed ? "完了" : "\(record.pendingCount)件処理中")
                        .font(Design.Typography.small)
                        .foregroundColor(Design.Colors.secondary)
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(Design.Colors.secondary)
                .font(.system(size: 12))
        }
        .terminalCard()
    }
}

// MARK: - Daily Detail View

struct DailyDetailView: View {
    let record: DailyRecord
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Design.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: Design.Spacing.lg) {
                        // Stats
                        statsSection
                        
                        // Combined transcription
                        transcriptionSection
                        
                        // Segments
                        segmentsSection
                    }
                    .padding(Design.Spacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(record.formattedDate)
                        .font(Design.Typography.headline)
                        .foregroundColor(Design.Colors.primary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Design.Colors.primary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var statsSection: some View {
        HStack(spacing: Design.Spacing.lg) {
            StatItem(title: "録音時間", value: record.formattedTotalDuration)
            StatItem(title: "セグメント", value: "\(record.segments.count)")
            StatItem(title: "処理済み", value: "\(record.processedCount)")
        }
        .terminalCard()
    }
    
    private var transcriptionSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            Text("Combined Transcription")
                .font(Design.Typography.caption)
                .foregroundColor(Design.Colors.secondary)
            
            if record.combinedTranscription.isEmpty {
                Text("No transcription available")
                    .font(Design.Typography.body)
                    .foregroundColor(Design.Colors.secondary)
                    .italic()
            } else {
                Text(record.combinedTranscription)
                    .font(Design.Typography.body)
                    .foregroundColor(Design.Colors.primary)
            }
        }
        .terminalCard()
    }
    
    private var segmentsSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            Text("Segments (\(record.segments.count))")
                .font(Design.Typography.caption)
                .foregroundColor(Design.Colors.secondary)
            
            ForEach(record.segments.sorted { $0.timestamp < $1.timestamp }, id: \.timestamp) { segment in
                SegmentDetailRow(segment: segment)
            }
        }
    }
}

// MARK: - Segment Detail Row

struct SegmentDetailRow: View {
    let segment: TranscriptionSegment
    
    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            HStack {
                Text(segment.formattedTimeRange)
                    .font(Design.Typography.caption)
                    .foregroundColor(Design.Colors.secondary)
                
                Spacer()
                
                Text(segment.status.displayText)
                    .font(Design.Typography.small)
                    .foregroundColor(statusColor)
            }
            
            if let transcription = segment.transcription, !transcription.isEmpty {
                Text(transcription)
                    .font(Design.Typography.body)
                    .foregroundColor(Design.Colors.primary)
            }
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

// MARK: - DailyRecord Identifiable Extension

extension DailyRecord: Identifiable {
    public var id: Date { date }
}

// MARK: - Preview

#Preview {
    HistoryView()
        .modelContainer(for: [
            DailyRecord.self,
            TranscriptionSegment.self
        ], inMemory: true)
}
