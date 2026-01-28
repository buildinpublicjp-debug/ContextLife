import Foundation
import SwiftData

/// SwiftDataとのやり取りを管理するサービス
/// 録音停止時にデータを保存、履歴の取得などを担当
@MainActor
@Observable
final class DataService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    /// 現在の日のDailyRecord（キャッシュ）
    private(set) var todayRecord: DailyRecord?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.todayRecord = DailyRecord.fetchOrCreate(for: Date(), in: modelContext)
    }
    
    // MARK: - Public Methods
    
    /// 録音完了時にセグメントを保存
    func saveRecordingSegment(
        timestamp: Date,
        duration: TimeInterval,
        audioFilePath: String
    ) throws {
        let segment = TranscriptionSegment(
            timestamp: timestamp,
            duration: duration,
            audioFilePath: audioFilePath
        )
        
        // 今日のレコードに追加
        ensureTodayRecord()
        todayRecord?.addSegment(segment)
        
        try modelContext.save()
    }
    
    /// 文字起こし結果を保存
    func saveTranscription(
        for segment: TranscriptionSegment,
        text: String
    ) throws {
        segment.setTranscription(text)
        try modelContext.save()
    }
    
    /// 文字起こし失敗を記録
    func markTranscriptionFailed(
        for segment: TranscriptionSegment,
        error: String
    ) throws {
        segment.markAsFailed(error: error)
        try modelContext.save()
    }
    
    /// 未処理のセグメントを取得
    func fetchPendingSegments(limit: Int = 10) -> [TranscriptionSegment] {
        TranscriptionSegment.fetchPending(in: modelContext, limit: limit)
    }
    
    /// 失敗したセグメントを取得
    func fetchFailedSegments() -> [TranscriptionSegment] {
        TranscriptionSegment.fetchFailed(in: modelContext)
    }
    
    /// 指定期間の履歴を取得
    func fetchHistory(from startDate: Date, to endDate: Date) -> [DailyRecord] {
        DailyRecord.fetch(from: startDate, to: endDate, in: modelContext)
    }
    
    /// 過去N日分の履歴を取得
    func fetchRecentHistory(days: Int) -> [DailyRecord] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        return fetchHistory(from: startDate, to: endDate)
    }
    
    /// 今日のデータを再取得
    func refreshTodayRecord() {
        todayRecord = DailyRecord.fetchOrCreate(for: Date(), in: modelContext)
    }
    
    /// セグメントをリトライ用にリセット
    func resetSegmentForRetry(_ segment: TranscriptionSegment) throws {
        segment.resetForRetry()
        try modelContext.save()
    }
    
    /// すべての失敗セグメントをリトライ用にリセット
    func resetAllFailedSegments() throws {
        let failed = fetchFailedSegments()
        for segment in failed {
            segment.resetForRetry()
        }
        try modelContext.save()
    }
    
    // MARK: - Private Methods
    
    private func ensureTodayRecord() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let existing = todayRecord,
           Calendar.current.isDate(existing.date, inSameDayAs: today) {
            return
        }
        
        todayRecord = DailyRecord.fetchOrCreate(for: Date(), in: modelContext)
    }
}

// MARK: - Statistics

extension DataService {
    
    /// 今日の統計
    var todayStats: DailyStats {
        ensureTodayRecord()
        guard let record = todayRecord else {
            return DailyStats.empty
        }
        
        return DailyStats(
            totalDuration: record.totalDuration,
            segmentCount: record.segments.count,
            processedCount: record.processedCount,
            pendingCount: record.pendingCount,
            failedCount: record.segments.filter { $0.processingFailed }.count
        )
    }
    
    /// 全体の統計
    func overallStats() -> OverallStats {
        let predicate = #Predicate<DailyRecord> { _ in true }
        let descriptor = FetchDescriptor<DailyRecord>(predicate: predicate)
        
        guard let records = try? modelContext.fetch(descriptor) else {
            return OverallStats.empty
        }
        
        let totalDuration = records.reduce(0) { $0 + $1.totalDuration }
        let totalSegments = records.reduce(0) { $0 + $1.segments.count }
        let totalDays = records.count
        
        return OverallStats(
            totalDuration: totalDuration,
            totalSegments: totalSegments,
            totalDays: totalDays
        )
    }
}

// MARK: - Stats Models

struct DailyStats {
    let totalDuration: TimeInterval
    let segmentCount: Int
    let processedCount: Int
    let pendingCount: Int
    let failedCount: Int
    
    static let empty = DailyStats(
        totalDuration: 0,
        segmentCount: 0,
        processedCount: 0,
        pendingCount: 0,
        failedCount: 0
    )
    
    var formattedDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
    
    var isFullyProcessed: Bool {
        pendingCount == 0
    }
}

struct OverallStats {
    let totalDuration: TimeInterval
    let totalSegments: Int
    let totalDays: Int
    
    static let empty = OverallStats(
        totalDuration: 0,
        totalSegments: 0,
        totalDays: 0
    )
    
    var formattedDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
    
    var averageDurationPerDay: TimeInterval {
        guard totalDays > 0 else { return 0 }
        return totalDuration / Double(totalDays)
    }
}
