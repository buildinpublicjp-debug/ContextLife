import SwiftUI
import SwiftData

/// メインのコンテンツビュー
/// TabViewで3つの画面を管理: Timeline, History, Settings
struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .timeline
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "waveform")
                }
                .tag(Tab.timeline)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                .tag(Tab.history)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .tint(Design.Colors.primary)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Tab Enum

enum Tab: String, CaseIterable {
    case timeline
    case history
    case settings
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [
            DailyRecord.self,
            TranscriptionSegment.self,
            LocationVisit.self
        ], inMemory: true)
}
