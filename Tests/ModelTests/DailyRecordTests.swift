import XCTest
import SwiftData
@testable import ContextLife

/// DailyRecordモデルのユニットテスト
final class DailyRecordTests: XCTestCase {
    
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
    
    func test_init_setsDateToStartOfDay() {
        // Given
        let now = Date()
        
        // When
        let record = DailyRecord(date: now)
        
        // Then
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        XCTAssertEqual(record.date, startOfDay)
    }
    
    func test_init_createsEmptySegments() {
        // Given & When
        let record = DailyRecord(date: Date())
        
        // Then
        XCTAssertTrue(record.segments.isEmpty)
    }
    
    func test_init_setsCreatedAtAndUpdatedAt() {
        // Given & When
        let before = Date()
        let record = DailyRecord(date: Date())
        let after = Date()
        
        // Then
        XCTAssertGreaterThanOrEqual(record.createdAt, before)
        XCTAssertLessThanOrEqual(record.createdAt, after)
        XCTAssertEqual(record.createdAt, record.updatedAt)
    }
    
    // MARK: - Segment Management Tests
    
    func test_addSegment_appendsToSegments() {
        // Given
        let record = DailyRecord(date: Date())
        let segment = TranscriptionSegment(
            timestamp: Date(),
            duration: 900,
            audioFilePath: "/path/to/audio.m4a"
        )
        
        // When
        record.addSegment(segment)
        
        // Then
        XCTAssertEqual(record.segments.count, 1)
        XCTAssertTrue(record.segments.contains(where: { $0 === segment }))
    }
    
    func test_addSegment_updatesUpdatedAt() {
        // Given
        let record = DailyRecord(date: Date())
        let originalUpdatedAt = record.updatedAt
        
        Thread.sleep(forTimeInterval: 0.01)
        
        let segment = TranscriptionSegment(
            timestamp: Date(),
            duration: 900,
            audioFilePath: "/path/to/audio.m4a"
        )
        
        // When
        record.addSegment(segment)
        
        // Then
        XCTAssertGreaterThan(record.updatedAt, originalUpdatedAt)
    }
    
    func test_addSegments_appendsMultipleSegments() {
        // Given
        let record = DailyRecord(date: Date())
        let segments = [
            TranscriptionSegment(timestamp: Date(), duration: 900, audioFilePath: "/path/1.m4a"),
            TranscriptionSegment(timestamp: Date(), duration: 900, audioFilePath: "/path/2.m4a"),
            TranscriptionSegment(timestamp: Date(), duration: 900, audioFilePath: "/path/3.m4a")
        ]
        
        // When
        record.addSegments(segments)
        
        // Then
        XCTAssertEqual(record.segments.count, 3)
    }
    
    // MARK: - Computed Properties Tests
    
    func test_totalDuration_calculatesCorrectly() {
        // Given
        let record = DailyRecord(date: Date())
        record.addSegment(TranscriptionSegment(timestamp: Date(), duration: 900, audioFilePath: "/1.m4a"))
        record.addSegment(TranscriptionSegment(timestamp: Date(), duration: 600, audioFilePath: "/2.m4a"))
        record.addSegment(TranscriptionSegment(timestamp: Date(), duration: 300, audioFilePath: "/3.m4a"))
        
        // When
        let total = record.totalDuration
        
        // Then
        XCTAssertEqual(total, 1800) // 900 + 600 + 300
    }
    
    func test_totalDuration_returnsZeroWhenNoSegments() {
        // Given
        let record = DailyRecord(date: Date())
        
        // When & Then
        XCTAssertEqual(record.totalDuration, 0)
    }
    
    func test_processedCount_countsCorrectly() {
        // Given
        let record = DailyRecord(date: Date())
        let segment1 = TranscriptionSegment(timestamp: Date(), duration: 900, audioFilePath: "/1.m4a")
        segment1.isProcessed = true
        let segment2 = TranscriptionSegment(timestamp: Date(), duration: 900, audioFilePath: "/2.m4a")
        segment2.isProcessed = true
        let segment3 = TranscriptionSegment(timestamp: Date(), duration: 900, audioFilePath: "/3.m4a")
        // segment3 is not processed
        
        record.addSegments([segment1, segment2, segment3])
        
        // When & Then
        XCTAssertEqual(record.processedCount, 2)
    }
    
    func test_pendingCount_countsCorrectly() {
        // Given
        let record = DailyRecord(date: Date())
        let segment1 = TranscriptionSegment(timestamp: Date(), duration: 900, audioFilePath: "/1.m4a")
        segment1.isProcessed = true
        let segment2 = TranscriptionSegment(timestamp: Date(), duration: 900, audioFilePath: "/2.m4a")
        // segment2 is pending
        let segment3 = TranscriptionSegment(timestamp: Date(), duration: 900, audioFilePath: "/3.m4a")
        segment3.processingFailed = true
        
        record.addSegments([segment1, segment2, segment3])
        
        // When & Then
        XCTAssertEqual(record.pendingCount, 1)
    }
    
    func test_isFullyProcessed_returnsTrueWhenAllProcessed() {
        // Given
        let record = DailyRecord(date: Date())
        let segment1 = TranscriptionSegment(timestamp: Date(), duration: 900, audioFilePath: "/1.m4a")
        segment1.isProcessed = true
        let segment2 = TranscriptionSegment(timestamp: Date(), duration: 900, audioFilePath: "/2.m4a")
        segment2.processingFailed = true // Failed also counts as "done"
        
        record.addSegments([segment1, segment2])
        
        // When & Then
        XCTAssertTrue(record.isFullyProcessed)
    }
    
    func test_isFullyProcessed_returnsFalseWhenPending() {
        // Given
        let record = DailyRecord(date: Date())
        let segment1 = TranscriptionSegment(timestamp: Date(), duration: 900, audioFilePath: "/1.m4a")
        segment1.isProcessed = true
        let segment2 = TranscriptionSegment(timestamp: Date(), duration: 900, audioFilePath: "/2.m4a")
        // segment2 is pending
        
        record.addSegments([segment1, segment2])
        
        // When & Then
        XCTAssertFalse(record.isFullyProcessed)
    }
    
    func test_combinedTranscription_joinsTextInOrder() {
        // Given
        let record = DailyRecord(date: Date())
        let segment1 = TranscriptionSegment(
            timestamp: Date().addingTimeInterval(-3600),
            duration: 900,
            audioFilePath: "/1.m4a"
        )
        segment1.transcription = "First segment"
        
        let segment2 = TranscriptionSegment(
            timestamp: Date().addingTimeInterval(-1800),
            duration: 900,
            audioFilePath: "/2.m4a"
        )
        segment2.transcription = "Second segment"
        
        let segment3 = TranscriptionSegment(
            timestamp: Date(),
            duration: 900,
            audioFilePath: "/3.m4a"
        )
        segment3.transcription = "Third segment"
        
        record.addSegments([segment3, segment1, segment2]) // Add in random order
        
        // When
        let combined = record.combinedTranscription
        
        // Then
        XCTAssertEqual(combined, "First segment\n\nSecond segment\n\nThird segment")
    }
    
    func test_combinedTranscription_skipsEmptyTranscriptions() {
        // Given
        let record = DailyRecord(date: Date())
        let segment1 = TranscriptionSegment(timestamp: Date(), duration: 900, audioFilePath: "/1.m4a")
        segment1.transcription = "Has text"
        let segment2 = TranscriptionSegment(timestamp: Date(), duration: 900, audioFilePath: "/2.m4a")
        segment2.transcription = ""
        let segment3 = TranscriptionSegment(timestamp: Date(), duration: 900, audioFilePath: "/3.m4a")
        segment3.transcription = nil
        
        record.addSegments([segment1, segment2, segment3])
        
        // When
        let combined = record.combinedTranscription
        
        // Then
        XCTAssertEqual(combined, "Has text")
    }
    
    // MARK: - Time Range Query Tests
    
    func test_segmentsInTimeRange_returnsCorrectSegments() {
        // Given
        let record = DailyRecord(date: Date())
        let now = Date()
        
        let segment1 = TranscriptionSegment(
            timestamp: now.addingTimeInterval(-7200), // 2 hours ago
            duration: 900,
            audioFilePath: "/1.m4a"
        )
        let segment2 = TranscriptionSegment(
            timestamp: now.addingTimeInterval(-3600), // 1 hour ago
            duration: 900,
            audioFilePath: "/2.m4a"
        )
        let segment3 = TranscriptionSegment(
            timestamp: now,
            duration: 900,
            audioFilePath: "/3.m4a"
        )
        
        record.addSegments([segment1, segment2, segment3])
        
        // When - Query for last 90 minutes
        let results = record.segments(
            from: now.addingTimeInterval(-5400),
            to: now.addingTimeInterval(100)
        )
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains(where: { $0 === segment2 }))
        XCTAssertTrue(results.contains(where: { $0 === segment3 }))
    }
    
    // MARK: - Static Helper Tests
    
    func test_normalizedDate_returnsStartOfDay() {
        // Given
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 28
        components.hour = 14
        components.minute = 30
        let date = Calendar.current.date(from: components)!
        
        // When
        let normalized = DailyRecord.normalizedDate(from: date)
        
        // Then
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.hour, from: normalized), 0)
        XCTAssertEqual(calendar.component(.minute, from: normalized), 0)
        XCTAssertEqual(calendar.component(.second, from: normalized), 0)
    }
}
