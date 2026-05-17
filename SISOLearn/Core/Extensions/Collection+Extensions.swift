extension Collection {
    /// 인덱스 범위를 벗어나면 nil 반환하는 안전한 서브스크립트
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
