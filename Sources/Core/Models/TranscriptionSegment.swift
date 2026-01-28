import Foundation
import SwiftData

/// 15分ごとの録音単位を表すモデル
@Model
final class TranscriptionSegment {
    
    // MARK: - Properties
    
    /// 録音開始時刻
    var timestamp: Date
    
    /// 録音時間（秒）
    var duration: TimeInterval
    
    /// 音声ファイルのパス
    var audioFilePath: String
    
    /// 文字起こし結果（nil = 未処理）
    var transcription: String?
    
    /// 処理済みフラグ
    var isProcessed: Bool
    
    /// 処理失敗フラグ
    var processingFailed: Bool
    
    /// 失敗時のエラーメッセージ
    var errorMessage: String?
    
    /// 作成日時
    var createdAt: Date
    
    // MARK: - Computed Properties
    
    /// 録音終了時刻
    var endTimestamp: Date {
        timestamp.addingTimeInterval(duration)
    }
    
    /// 時刻のフォーマット済み文字列 (HH:mm)
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
    
    /// 時間範囲のフォーマット済み文字列 (HH:mm - HH:mm)
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: timestamp)) - \(formatter.string(from: endTimestamp))"
    }
    
    /// 音声ファイルのURL
    var audioFileURL: URL? {
        URL(string: audioFilePath)
    }
    
    /// 文字起こしが存在するか
    var hasTranscription: Bool {
        guard let text = transcription else { return false }
        return !text.isEmpty
    }
    
    /// ステータス表示用
    var status: SegmentStatus {
        if processingFailed {
            return .failed
        } else if isProcessed {
            return .completed
        } else {
            return .pending
        }
    }
    
    /// フォーマット済み録音時間
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// 文字起こしのプレビュー（最初の100文字）
    var transcriptionPreview: String {
        guard let text = transcription, !text.isEmpty else {
            return "文字起こしなし"
        }
        if text.count <= 100 {
            return text
        }
        return String(text.prefix(100)) + "..."
    }
    
    // MARK: - Initialization
    
    init(
        timestamp: Date,
        duration: TimeInterval,
        audioFilePath: String
    ) {
        self.timestamp = timestamp
        self.duration = duration
        self.audioFilePath = audioFilePath
        self.transcription = nil
        self.isProcessed = false
        self.processingFailed = false
        self.errorMessage = nil
        self.createdAt = Date()
    }
    
    // MARK: - Methods
    
    /// 文字起こし結果を設定
    func setTranscription(_ text: String) {
        self.transcription = text
        self.isProcessed = true
        self.processingFailed = false
        self.errorMessage = nil
    }
    
    /// 処理失敗を記録
    func markAsFailed(error: String) {
        self.isProcessed = false
        self.processingFailed = true
        self.errorMessage = error
    }
    
    /// リトライ用にリセット
    func resetForRetry() {
        self.isProcessed = false
        self.processingFailed = false
        self.errorMessage = nil
    }
}

// MARK: - SegmentStatus

enum SegmentStatus: String, CaseIterable {
    case pending
    case completed
    case failed
    
    var displayText: String {
        switch self {
        case .pending: return "処理待ち"
        case .completed: return "完了"
        case .failed: return "失敗"
        }
    }
    
    var iconName: String {
        switch self {
        case .pending: return "clock"
        case .completed: return "checkmark.circle"
        case .failed: return "exclamationmark.triangle"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "gray"
        case .completed: return "green"
        case .failed: return "red"
        }
    }
}

// MARK: - Static Helpers

extension TranscriptionSegment {
    
    /// 未処理のセグメントを取得
    @MainActor
    static func fetchPending(in context: ModelContext, limit: Int = 10) -> [TranscriptionSegment] {
        let predicate = #Predicate<TranscriptionSegment> { segment in
            !segment.isProcessed && !segment.processingFailed
        }
        
        var descriptor = FetchDescriptor<TranscriptionSegment>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\TranscriptionSegment.timestamp)]
        descriptor.fetchLimit = limit
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// 失敗したセグメントを取得
    @MainActor
    static func fetchFailed(in context: ModelContext) -> [TranscriptionSegment] {
        let predicate = #Predicate<TranscriptionSegment> { segment in
            segment.processingFailed
        }
        
        var descriptor = FetchDescriptor<TranscriptionSegment>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\TranscriptionSegment.timestamp)]
        
        return (try? context.fetch(descriptor)) ?? []
    }
}
