import SwiftUI

enum AppTheme {
    // MARK: - 주요 색상
    static let primary = Color.orange
    static let secondary = Color(red: 0.55, green: 0.27, blue: 0.07)
    static let background = Color(.systemBackground)
    static let cardBg = Color(.secondarySystemBackground)
    static let accent = Color.yellow

    // MARK: - 과목별 색상
    static let mathColor = Color.blue
    static let englishColor = Color.green
    static let scienceColor = Color.purple
    static let koreanColor = Color.red

    static func subjectColor(_ subject: Subject) -> Color {
        switch subject {
        case .math:    return mathColor
        case .english: return englishColor
        case .science: return scienceColor
        case .korean:  return koreanColor
        }
    }

    // MARK: - 타이포그래피
    static let titleFont = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let headlineFont = Font.system(.headline, design: .rounded, weight: .semibold)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let captionFont = Font.system(.caption, design: .rounded)
}
