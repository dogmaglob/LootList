import SwiftUI
import SwiftData

struct EventLogView: View {
    @Query private var events: [LootEvent]

    init(campaign: Campaign?) {
        let campaignID = campaign?.id
        _events = Query(
            filter: #Predicate<LootEvent> { event in
                event.campaign?.id == campaignID
            },
            sort: \LootEvent.timestamp,
            order: .reverse
        )
    }

    var body: some View {
        Group {
            if events.isEmpty {
                ContentUnavailableView(
                    "No Events Yet",
                    systemImage: "scroll",
                    description: Text("Events are recorded when loot is found, used, or sold.")
                )
            } else {
                List {
                    ForEach(events) { event in
                        LootEventRowView(event: event)
                    }
                }
            }
        }
        .navigationTitle("Event Log")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LootEventRowView: View {
    let event: LootEvent

    var body: some View {
        HStack {
            Image(systemName: event.type.systemImage)
                .foregroundStyle(event.type.color)
                .font(.title3)
            VStack(alignment: .leading) {
                Text(event.itemName)
                    .font(.headline)
                Text(event.type.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
