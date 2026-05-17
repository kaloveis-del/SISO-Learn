import Foundation

extension Date {
    /// 오늘 날짜인지 확인
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// 어제 날짜인지 확인
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// "yyyy.MM.dd" 형식 문자열
    var displayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: self)
    }
}
