import Foundation

enum SortMode: String, CaseIterable {
    case latest
    case usage

    var displayName: String {
        switch self {
        case .latest: return "Newest"
        case .usage: return "Most Used"
        }
    }
}
