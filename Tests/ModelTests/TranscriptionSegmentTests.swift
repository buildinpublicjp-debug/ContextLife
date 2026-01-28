import XCTest
import SwiftData
@testable import ContextLife

/// TranscriptionSegmentモデルのユニットテスト
final class TranscriptionSegmentTests: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUp() {
        super.setUp()
        let schema = Schema([DailyRecord.self, TranscriptionSegment.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }
    
    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_setsPropertiesCorrectly() {
        // Given
        let timestamp = Date()
        let duration: TimeInterval = 900
        let path = "/path/to/audio.m4a"
        
        // When
        let segment = TranscriptionSegment(
            timestamp: timestamp,
            duration: duration,
            audioFilePath: path
        )
        
        // Then
        XCTAssertEqual(segment.timestamp, timestamp)
        XCTAssertEqual(segment.duration, duration)
        XCTAssertEqual(segment.audioFilePath, path)
        XCTAssertNil(segment.transcription)
        XCTAssertFalse(segment.isProcessed)
        XCTAssertFalse(segment.processingFailed)
        XCTAssertNil(segment.errorMessage)
    }
    
    func test_init_setsCreatedAt() {
        // Given & When
        let before = Date()
        let segment = TranscriptionSegment(
            timestamp: Date(),
            duration: 900,
            audioFilePath: "/path.m4a"
        )
        let after = Date()
        
        // Then
        XCTAssertGreaterThanOrEqual(segment.createdAt, before)
        XCTAssertLessThanOrEqual(segment.createdAt, after)
    }
    
    // MARK: - Computed Properties Tests
    
    func test_endTimestamp_calculatesCorrectly() {
        // Given
        let timestamp = Date()
        let duration: TimeInterval = 900
        let segment = TranscriptionSegment(
            timestamp: timestamp,
            duration: duration,
            audioFilePath: "/path.m4a"
        )
        
        // When
        let endTime = segment.endTimestamp
        
        // Then
        XCTAssertEqual(endTime.timeIntervalSince(timestamp), duration)
    }
    
    func test_formattedTime_returnsCorrectFormat() {
        // Given
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 28
        components.hour = 14
        components.minute = 30
        let timestamp = Calendar.current.date(from: components)!
        
        let segment = TranscriptionSegment(
            timestamp: timestamp,
            duration: 900,
            audioFilePath: "/path.m4a"
        )
        
        // When & Then
        XCTAssertEqual(segment.formattedTime, "14:30")
    }
    
    func test_formattedTimeRange_returnsCorrectFormat() {
        // Given
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 28
        components.hour = 14
        components.minute = 30
        let timestamp = Calendar.current.date(from: components)!
        
        let segment = TranscriptionSegment(
            timestamp: timestamp,
            duration: 900, // 15 minutes
            audioFilePath: "/path.m4a"
        )
        
        // When & Then
        XCTAssertEqual(segment.formattedTimeRange, "14:30 - 14:45")
    }
    
    func test_hasTranscription_returnsFalseWhenNil() {
        // Given
        let segment = TranscriptionSegment(
            timestamp: Date(),
            duration: 900,
            audioFilePath: "/path.m4a"
        )
        
        // When & Then
        XCTAssertFalse(segment.hasTranscription)
    }
    
    func test_hasTranscription_returnsFalseWhenEmpty() {
        // Given
        let segment = TranscriptionSegment(
            timestamp: Date(),
            duration: 900,
            audioFilePath: "/path.m4a"
        )
        segment.transcription = ""
        
        // When & Then
        XCTAssertFalse(segment.hasTranscription)
    }
    
    func test_hasTranscription_returnsTrueWhenHasText() {
        // Given
        let segment = TranscriptionSegment(
            timestamp: Date(),
            duration: 900,
            audioFilePath: "/path.m4a"
        )
        segment.transcription = "Some text"
        
        // When & Then
        XCTAssertTrue(segment.hasTranscription)
    }
    
    func test_status_returnsPendingByDefault() {
        // Given
        let segment = TranscriptionSegment(
            timestamp: Date(),
            duration: 900,
            audioFilePath: "/path.m4a"
        )
        
        // When & Then
        XCTAssertEqual(segment.status, .pending)
    }
    
    func test_status_returnsCompletedWhenProcessed() {
        // Given
        let segment = TranscriptionSegment(
            timestamp: Date(),
            duration: 900,
            audioFilePath: "/path.m4a"
        )
        segment.isProcessed = true
        
        // When & Then
        XCTAssertEqual(segment.status, .completed)
    }
    
    func test_status_returnsFailedWhenFailed() {
        // Given
        let segment = TranscriptionSegment(
            timestamp: Date(),
            duration: 900,
            audioFilePath: "/path.m4a"
        )
        segment.processingFailed = true
        
        // When & Then
        XCTAssertEqual(segment.status, .failed)
    }
    
    func test_formattedDuration_formatsCorrectly() {
        // Given
        let segment = TranscriptionSegment(
            timestamp: Date(),
            duration: 185, // 3分5秒
            audioFilePath: "/path.m4a"
        )
        
        // When & Then
        XCTAssertEqual(segment.formattedDuration, "3:05")
    }
    
    func test_transcriptionPreview_truncatesLongText() {
        // Given
        let segment = TranscriptionSegment(
            timestamp: Date(),
            duration: 900,
            audioFilePath: "/path.m4a"
        )
        let longText = String(repeating: "a", count: 200)
        segment.transcription = longText
        
        // When
        let preview = segment.transcriptionPreview
        
        // Then
        XCTAssertEqual(preview.count, 103) // 100 chars + "..."
        XCTAssertTrue(preview.hasSuffix("..."))
    }
    
    func test_transcriptionPreview_returnsFullTextWhenShort() {
        // Given
        let segment = TranscriptionSegment(
            timestamp: Date(),
            duration: 900,
            audioFilePath: "/path.m4a"
        )
        segment.transcription = "Short text"
        
        // When & Then
        XCTAssertEqual(segment.transcriptionPreview, "Short text")
    }
    
    // MARK: - Method Tests
    
    func test_setTranscription_setsAllFlags() {
        // Given
        let segment = TranscriptionSegment(
            timestamp: Date(),
            duration: 900,
            audioFilePath: "/path.m4a"
        )
        segment.processingFailed = true
        segment.errorMessage = "Previous error"
        
        // When
        segment.setTranscription("Transcribed text")
        
        // Then
        XCTAssertEqual(segment.transcription, "Transcribed text")
        XCTAssertTrue(segment.isProcessed)
        XCTAssertFalse(segment.processingFailed)
        XCTAssertNil(segment.errorMessage)
    }
    
    func test_markAsFailed_setsErrorState() {
        // Given
        let segment = TranscriptionSegment(
            timestamp: Date(),
            duration: 900,
            audioFilePath: "/path.m4a"
        )
        
        // When
        segment.markAsFailed(error: "Transcription failed")
        
        // Then
        XCTAssertFalse(segment.isProcessed)
        XCTAssertTrue(segment.processingFailed)
        XCTAssertEqual(segment.errorMessage, "Transcription failed")
    }
    
    func test_resetForRetry_clearsFlags() {
        // Given
        let segment = TranscriptionSegment(
            timestamp: Date(),
            duration: 900,
            audioFilePath: "/path.m4a"
        )
        segment.processingFailed = true
        segment.errorMessage = "Error"
        segment.isProcessed = true
        
        // When
        segment.resetForRetry()
        
        // Then
        XCTAssertFalse(segment.isProcessed)
        XCTAssertFalse(segment.processingFailed)
        XCTAssertNil(segment.errorMessage)
    }
    
    // MARK: - SegmentStatus Tests
    
    func test_segmentStatus_displayText() {
        XCTAssertEqual(SegmentStatus.pending.displayText, "処理待ち")
        XCTAssertEqual(SegmentStatus.completed.displayText, "完了")
        XCTAssertEqual(SegmentStatus.failed.displayText, "失敗")
    }
    
    func test_segmentStatus_iconName() {
        XCTAssertEqual(SegmentStatus.pending.iconName, "clock")
        XCTAssertEqual(SegmentStatus.completed.iconName, "checkmark.circle")
        XCTAssertEqual(SegmentStatus.failed.iconName, "exclamationmark.triangle")
    }
}
