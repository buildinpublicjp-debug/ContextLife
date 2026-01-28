import Foundation
import SwiftData
import CoreLocation

/// 滞在地を記録するモデル
/// TranscriptionSegmentとは時刻ベースで紐付け（リレーションなし、疎結合）
@Model
final class LocationVisit {
    
    // MARK: - Properties
    
    /// 場所名（Apple Mapsから取得）
    var placeName: String
    
    /// 緯度
    var latitude: Double
    
    /// 経度
    var longitude: Double
    
    /// 到着時刻
    var arrivalDate: Date
    
    /// 出発時刻（nil = 現在滞在中）
    var departureDate: Date?
    
    /// 作成日時
    var createdAt: Date
    
    // MARK: - Computed Properties
    
    /// 滞在時間（秒）
    var duration: TimeInterval? {
        guard let departure = departureDate else { return nil }
        return departure.timeIntervalSince(arrivalDate)
    }
    
    /// 滞在時間のフォーマット済み文字列
    var formattedDuration: String {
        guard let duration = duration else { return "滞在中" }
        
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
    
    /// 現在滞在中かどうか
    var isCurrentlyVisiting: Bool {
        departureDate == nil
    }
    
    /// 座標
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// 時刻のフォーマット済み文字列
    var formattedArrivalTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: arrivalDate)
    }
    
    /// 時間範囲のフォーマット済み文字列
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let arrival = formatter.string(from: arrivalDate)
        
        if let departure = departureDate {
            return "\(arrival) - \(formatter.string(from: departure))"
        } else {
            return "\(arrival) - 現在"
        }
    }
    
    /// タイムライン表示用アイコン
    var iconName: String {
        if isCurrentlyVisiting {
            return "location.fill"
        } else {
            return "mappin.circle"
        }
    }
    
    // MARK: - Initialization
    
    init(
        placeName: String,
        latitude: Double,
        longitude: Double,
        arrivalDate: Date
    ) {
        self.placeName = placeName
        self.latitude = latitude
        self.longitude = longitude
        self.arrivalDate = arrivalDate
        self.departureDate = nil
        self.createdAt = Date()
    }
    
    // MARK: - Methods
    
    /// 出発を記録
    func markDeparture(at date: Date = Date()) {
        self.departureDate = date
    }
    
    /// 指定時刻がこの滞在期間内かどうか
    func contains(date: Date) -> Bool {
        let endDate = departureDate ?? Date()
        return date >= arrivalDate && date <= endDate
    }
}

// MARK: - Static Helpers

extension LocationVisit {
    
    /// 指定期間内の滞在記録を取得
    @MainActor
    static func fetch(
        from startDate: Date,
        to endDate: Date,
        in context: ModelContext
    ) -> [LocationVisit] {
        let predicate = #Predicate<LocationVisit> { visit in
            visit.arrivalDate >= startDate && visit.arrivalDate <= endDate
        }
        
        var descriptor = FetchDescriptor<LocationVisit>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\LocationVisit.arrivalDate)]
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// 現在滞在中の場所を取得
    @MainActor
    static func fetchCurrentVisit(in context: ModelContext) -> LocationVisit? {
        let predicate = #Predicate<LocationVisit> { visit in
            visit.departureDate == nil
        }
        
        var descriptor = FetchDescriptor<LocationVisit>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\LocationVisit.arrivalDate, order: .reverse)]
        descriptor.fetchLimit = 1
        
        return try? context.fetch(descriptor).first
    }
    
    /// 指定日のすべての滞在記録を取得
    @MainActor
    static func fetchForDate(_ date: Date, in context: ModelContext) -> [LocationVisit] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return fetch(from: startOfDay, to: endOfDay, in: context)
    }
}
