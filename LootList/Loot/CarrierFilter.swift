import Foundation

enum CarrierFilter: Equatable {
    case all
    case stash
    case specific(Carrier)

    static func == (lhs: CarrierFilter, rhs: CarrierFilter) -> Bool {
        switch (lhs, rhs) {
        case (.all, .all), (.stash, .stash): return true
        case let (.specific(a), .specific(b)): return a.id == b.id
        default: return false
        }
    }
}
