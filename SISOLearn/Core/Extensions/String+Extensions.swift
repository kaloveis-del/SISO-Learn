import Foundation

extension String {
    /// 앞뒤 공백 제거 후 비어있는지 확인
    var isBlank: Bool {
        trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// 최대 길이로 자르기
    func truncated(to maxLength: Int) -> String {
        guard count > maxLength else { return self }
        return String(prefix(maxLength))
    }
}
