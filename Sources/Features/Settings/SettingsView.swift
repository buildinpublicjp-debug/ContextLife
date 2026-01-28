import SwiftUI

/// 設定画面
/// 録音ON/OFF、Obsidian連携、Pro機能など
struct SettingsView: View {
    
    @AppStorage("isAutoRecordEnabled") private var isAutoRecordEnabled = false
    @AppStorage("isLocationEnabled") private var isLocationEnabled = true
    @AppStorage("obsidianFolderPath") private var obsidianFolderPath = ""
    
    @State private var showingProUpgrade = false
    
    // TODO: RevenueCat integration
    private var isPro: Bool { false }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Design.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Design.Spacing.lg) {
                        // Recording Section
                        recordingSection
                        
                        // Data Section
                        dataSection
                        
                        // Pro Section
                        proSection
                        
                        // About Section
                        aboutSection
                        
                        // Debug Section (DEV only)
                        #if DEBUG
                        debugSection
                        #endif
                    }
                    .padding(Design.Spacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SETTINGS")
                        .font(Design.Typography.headline)
                        .foregroundColor(Design.Colors.primary)
                }
            }
            .sheet(isPresented: $showingProUpgrade) {
                ProUpgradeView()
            }
        }
    }
    
    // MARK: - Sections
    
    private var recordingSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            SectionHeader(title: "Recording")
            
            SettingsToggle(
                title: "Auto Record",
                subtitle: "Start recording when app launches",
                isOn: $isAutoRecordEnabled
            )
            
            SettingsToggle(
                title: "Location Tracking",
                subtitle: "Record location with audio",
                isOn: $isLocationEnabled
            )
        }
    }
    
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            SectionHeader(title: "Data")
            
            SettingsRow(
                title: "Obsidian Folder",
                value: obsidianFolderPath.isEmpty ? "Not Set" : obsidianFolderPath,
                isPro: true,
                isProUser: isPro
            ) {
                if isPro {
                    // TODO: Open folder picker
                } else {
                    showingProUpgrade = true
                }
            }
            
            SettingsRow(
                title: "Export Today",
                value: "",
                isPro: true,
                isProUser: isPro
            ) {
                if isPro {
                    // TODO: Export functionality
                } else {
                    showingProUpgrade = true
                }
            }
        }
    }
    
    private var proSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            SectionHeader(title: "Pro")
            
            if isPro {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Design.Colors.primary)
                    
                    Text("Pro Active")
                        .font(Design.Typography.body)
                        .foregroundColor(Design.Colors.primary)
                    
                    Spacer()
                }
                .terminalCard()
            } else {
                Button {
                    showingProUpgrade = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: Design.Spacing.xs) {
                            Text("Upgrade to Pro")
                                .font(Design.Typography.headline)
                                .foregroundColor(Design.Colors.primary)
                            
                            Text("Unlimited history, export, high-quality transcription")
                                .font(Design.Typography.caption)
                                .foregroundColor(Design.Colors.secondary)
                        }
                        
                        Spacer()
                        
                        Text("$4.99/mo")
                            .font(Design.Typography.body)
                            .foregroundColor(Design.Colors.primary)
                    }
                    .terminalCard()
                }
            }
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            SectionHeader(title: "About")
            
            SettingsRow(title: "Version", value: "1.0.0 (MVP)")
            SettingsRow(title: "Build", value: "2026.01.28")
        }
    }
    
    #if DEBUG
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            SectionHeader(title: "Debug")
            
            Button {
                // TODO: Add test data
            } label: {
                Text("Add Test Data")
                    .secondaryButton()
            }
            
            Button {
                // TODO: Clear all data
            } label: {
                Text("Clear All Data")
                    .font(Design.Typography.body)
                    .foregroundColor(Design.Colors.error)
            }
        }
    }
    #endif
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title.uppercased())
            .font(Design.Typography.small)
            .foregroundColor(Design.Colors.secondary)
            .padding(.top, Design.Spacing.sm)
    }
}

// MARK: - Settings Toggle

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Design.Spacing.xs) {
                Text(title)
                    .font(Design.Typography.body)
                    .foregroundColor(Design.Colors.primary)
                
                Text(subtitle)
                    .font(Design.Typography.caption)
                    .foregroundColor(Design.Colors.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(Design.Colors.primary)
        }
        .terminalCard()
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let title: String
    let value: String
    var isPro: Bool = false
    var isProUser: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button {
            action?()
        } label: {
            HStack {
                Text(title)
                    .font(Design.Typography.body)
                    .foregroundColor(Design.Colors.primary)
                
                if isPro && !isProUser {
                    Text("PRO")
                        .font(Design.Typography.small)
                        .foregroundColor(Design.Colors.background)
                        .padding(.horizontal, Design.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(Design.Colors.primary)
                        .cornerRadius(Design.CornerRadius.sm)
                }
                
                Spacer()
                
                if !value.isEmpty {
                    Text(value)
                        .font(Design.Typography.caption)
                        .foregroundColor(Design.Colors.secondary)
                }
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Design.Colors.secondary)
                }
            }
            .terminalCard()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pro Upgrade View

struct ProUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Design.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: Design.Spacing.xl) {
                    // Icon
                    Image(systemName: "star.fill")
                        .font(.system(size: 64))
                        .foregroundColor(Design.Colors.primary)
                    
                    // Title
                    Text("ContextLife Pro")
                        .font(Design.Typography.largeTitle)
                        .foregroundColor(Design.Colors.primary)
                    
                    // Features
                    VStack(alignment: .leading, spacing: Design.Spacing.md) {
                        ProFeatureRow(icon: "clock", text: "Unlimited history")
                        ProFeatureRow(icon: "square.and.arrow.up", text: "Export to Obsidian")
                        ProFeatureRow(icon: "waveform", text: "High-quality transcription")
                        ProFeatureRow(icon: "icloud", text: "iCloud sync")
                    }
                    .padding(Design.Spacing.lg)
                    
                    Spacer()
                    
                    // Price
                    VStack(spacing: Design.Spacing.sm) {
                        Text("$4.99/month")
                            .font(Design.Typography.title)
                            .foregroundColor(Design.Colors.primary)
                        
                        Text("or $39.99/year (save 2 months)")
                            .font(Design.Typography.caption)
                            .foregroundColor(Design.Colors.secondary)
                    }
                    
                    // Subscribe Button
                    Button {
                        // TODO: RevenueCat purchase
                    } label: {
                        Text("Subscribe")
                            .frame(maxWidth: .infinity)
                            .primaryButton()
                    }
                    
                    // Restore
                    Button {
                        // TODO: RevenueCat restore
                    } label: {
                        Text("Restore Purchase")
                            .font(Design.Typography.caption)
                            .foregroundColor(Design.Colors.secondary)
                    }
                }
                .padding(Design.Spacing.lg)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Design.Colors.secondary)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ProFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(Design.Colors.primary)
                .frame(width: 24)
            
            Text(text)
                .font(Design.Typography.body)
                .foregroundColor(Design.Colors.primary)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
