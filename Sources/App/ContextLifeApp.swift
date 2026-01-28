import SwiftUI
import SwiftData

@main
struct ContextLifeApp: App {
    
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                DailyRecord.self,
                TranscriptionSegment.self,
                LocationVisit.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
