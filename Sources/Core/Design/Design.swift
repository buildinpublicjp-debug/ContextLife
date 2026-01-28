import SwiftUI

/// ContextLifeのデザインシステム
/// "Terminal meets Zen" - ミニマル、レトロ、静か
enum Design {
    
    // MARK: - Colors
    
    enum Colors {
        /// メイン背景色 #0D1117
        static let background = Color(hex: "0D1117")
        
        /// ターミナルグリーン #00FF66
        static let primary = Color(hex: "00FF66")
        
        /// セカンダリテキスト
        static let secondary = Color(hex: "8B949E")
        
        /// エラー/失敗
        static let error = Color(hex: "F85149")
        
        /// 警告
        static let warning = Color(hex: "D29922")
        
        /// カードの背景
        static let cardBackground = Color(hex: "161B22")
        
        /// ボーダー
        static let border = Color(hex: "30363D")
    }
    
    // MARK: - Typography
    
    enum Typography {
        /// メインフォント
        static let mono = Font.custom("SF Mono", size: 14)
        
        /// 大きいタイトル
        static let largeTitle = Font.custom("SF Mono", size: 28).weight(.bold)
        
        /// タイトル
        static let title = Font.custom("SF Mono", size: 20).weight(.semibold)
        
        /// 見出し
        static let headline = Font.custom("SF Mono", size: 16).weight(.medium)
        
        /// 本文
        static let body = Font.custom("SF Mono", size: 14)
        
        /// キャプション
        static let caption = Font.custom("SF Mono", size: 12)
        
        /// 小さいテキスト
        static let small = Font.custom("SF Mono", size: 10)
    }
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    enum CornerRadius {
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

extension View {
    /// ターミナル風カードスタイル
    func terminalCard() -> some View {
        self
            .padding(Design.Spacing.md)
            .background(Design.Colors.cardBackground)
            .cornerRadius(Design.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Design.CornerRadius.md)
                    .stroke(Design.Colors.border, lineWidth: 1)
            )
    }
    
    /// プライマリボタンスタイル
    func primaryButton() -> some View {
        self
            .font(Design.Typography.headline)
            .foregroundColor(Design.Colors.background)
            .padding(.horizontal, Design.Spacing.lg)
            .padding(.vertical, Design.Spacing.sm)
            .background(Design.Colors.primary)
            .cornerRadius(Design.CornerRadius.sm)
    }
    
    /// セカンダリボタンスタイル
    func secondaryButton() -> some View {
        self
            .font(Design.Typography.headline)
            .foregroundColor(Design.Colors.primary)
            .padding(.horizontal, Design.Spacing.lg)
            .padding(.vertical, Design.Spacing.sm)
            .background(Color.clear)
            .cornerRadius(Design.CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: Design.CornerRadius.sm)
                    .stroke(Design.Colors.primary, lineWidth: 1)
            )
    }
}
