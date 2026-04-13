import SwiftUI

extension LootEventType {
    var label: String {
        switch self {
        case .found: "Found"
        case .sold: "Sold"
        case .used: "Used"
        }
    }

    var systemImage: String {
        switch self {
        case .found: "plus.circle.fill"
        case .sold: "tag.fill"
        case .used: "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .found: .green
        case .sold: .orange
        case .used: .blue
        }
    }
}
