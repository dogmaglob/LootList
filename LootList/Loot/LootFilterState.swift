import Foundation
import Observation

@Observable
@MainActor
final class LootFilterState {
    var selectedCategories: Set<UUID> = []
    var dateFrom: Date? = nil
    var dateTo: Date? = nil
    var minValue: String = ""
    var maxValue: String = ""

    var isActive: Bool {
        !selectedCategories.isEmpty ||
        dateFrom != nil ||
        dateTo != nil ||
        !minValue.isEmpty ||
        !maxValue.isEmpty
    }

    func reset() {
        selectedCategories = []
        dateFrom = nil
        dateTo = nil
        minValue = ""
        maxValue = ""
    }
}
