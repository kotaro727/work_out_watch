import SwiftUI

enum Theme {
    static let background = Color(red: 16 / 255, green: 16 / 255, blue: 18 / 255)
    static let backgroundElevated = Color(red: 24 / 255, green: 24 / 255, blue: 26 / 255)
    static let surface = Color(red: 32 / 255, green: 32 / 255, blue: 36 / 255)
    static let surfaceHighlight = Color(red: 45 / 255, green: 45 / 255, blue: 50 / 255)
    static let accent = Color(red: 1.0, green: 0.43, blue: 0.17)
    static let accentSecondary = Color(red: 1.0, green: 0.58, blue: 0.24)
    static let accentMuted = Color(red: 1.0, green: 0.30, blue: 0.12)
    static let success = Color(red: 0.38, green: 0.75, blue: 0.32)
    static let textPrimary = Color(red: 0.95, green: 0.95, blue: 0.95)
    static let textSecondary = Color(red: 0.75, green: 0.75, blue: 0.75)
    static let textTertiary = Color(red: 0.55, green: 0.55, blue: 0.55)
    static let border = Color.white.opacity(0.08)

    static let accentGradient = LinearGradient(
        colors: [Theme.accent, Theme.accentSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
