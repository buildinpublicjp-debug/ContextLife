import Foundation
import SwiftData

/// 1日分の記録を管理するモデル
/// 同じ日付のデータは同じDailyRecordに追加される
@Model
final class DailyRecord {
    
    // MARK: - Properties
    
    /// 記録の日付（時刻は00:00:00に正規化）
    var date: Date
    
    /// この日のセグメント群
    @Relationship(deleteRule: .cascade)
    var segments: [TranscriptionSegment]
    
    /// 作成日時
    var createdAt: Date
    
    /// 最終更新日時
    var updatedAt: Date
    
    // MARK: - Computed Properties
    
    /// 合計録音時間（秒）
    var totalDuration: TimeInterval {
        segments.reduce(0) { $0 + $1.duration }
    }
    
    /// 処理済みセグメント数
    var processedCount: Int {
        segments.filter { $0.isProcessed }.count
    }
    
    /// 未処理セグメント数
    var pendingCount: Int {
        segments.filter { !$0.isProcessed && !$0.processingFailed }.count
    }
    
    /// すべて処理済みか
    var isFullyProcessed: Bool {
        segments.allSatisfy { $0.isProcessed || $0.processingFailed }
    }
    
    /// 文字起こしテキストを時系列で結合
    var combinedTranscription: String {
        segments
            .sorted { $0.timestamp < $1.timestamp }
            .compactMap { $0.transcription }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }
    
    /// フォーマット済み日付文字列
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d（E）"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    /// フォーマット済み合計時間
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
    
    // MARK: - Initialization
    
    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
        self.segments = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Methods
    
    /// セグメントを追加
    func addSegment(_ segment: TranscriptionSegment) {
        segments.append(segment)
        updatedAt = Date()
    }
    
    /// 複数セグメントを追加
    func addSegments(_ newSegments: [TranscriptionSegment]) {
        segments.append(contentsOf: newSegments)
        updatedAt = Date()
    }
    
    /// 時間範囲内のセグメントを取得
    func segments(from startTime: Date, to endTime: Date) -> [TranscriptionSegment] {
        segments.filter { segment in
            segment.timestamp >= startTime && segment.timestamp <= endTime
        }.sorted { $0.timestamp < $1.timestamp }
    }
}

// MARK: - Static Helpers

extension DailyRecord {
    
    /// 日付から正規化されたDateを生成（時刻を00:00:00に）
    static func normalizedDate(from date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    /// 今日のDailyRecordを取得または作成
    @MainActor
    static func fetchOrCreate(for date: Date, in context: ModelContext) -> DailyRecord {
        let normalizedDate = normalizedDate(from: date)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: normalizedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<DailyRecord> { record in
            record.date >= startOfDay && record.date < endOfDay
        }
        
        let descriptor = FetchDescriptor<DailyRecord>(predicate: predicate)
        
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        
        let newRecord = DailyRecord(date: date)
        context.insert(newRecord)
        return newRecord
    }
    
    /// 指定期間のDailyRecordを取得
    @MainActor
    static func fetch(from startDate: Date, to endDate: Date, in context: ModelContext) -> [DailyRecord] {
        let start = normalizedDate(from: startDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: normalizedDate(from: endDate))!
        
        let predicate = #Predicate<DailyRecord> { record in
            record.date >= start && record.date < end
        }
        
        var descriptor = FetchDescriptor<DailyRecord>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\DailyRecord.date, order: .reverse)]
        
        return (try? context.fetch(descriptor)) ?? []
    }
}
