import Foundation

enum CarrierFilter: Equatable {
    case all
    case unassigned
    case specific(Carrier)

    static func == (lhs: CarrierFilter, rhs: CarrierFilter) -> Bool {
        switch (lhs, rhs) {
        case (.all, .all), (.unassigned, .unassigned): return true
        case let (.specific(a), .specific(b)): return a.id == b.id
        default: return false
        }
    }
}
