import SwiftUI
import SwiftData

struct CampaignListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Campaign.createdAt) private var campaigns: [Campaign]

    @State private var newName = ""
    @State private var campaignToDelete: Campaign?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Campaign name", text: $newName)
                        Button("Add") {
                            let campaign = Campaign(name: newName.trimmingCharacters(in: .whitespaces))
                            modelContext.insert(campaign)
                            newName = ""
                        }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section {
                    if campaigns.isEmpty {
                        ContentUnavailableView(
                            "No Campaigns",
                            systemImage: "scroll",
                            description: Text("Add a campaign above to get started.")
                        )
                    } else {
                        ForEach(campaigns) { campaign in
                            NavigationLink(value: campaign) {
                                CampaignRowView(campaign: campaign)
                            }
                        }
                        .onDelete(perform: confirmDelete)
                    }
                }
            }
            .navigationTitle("Campaigns")
            .navigationDestination(for: Campaign.self) { campaign in
                LootListView(campaign: campaign)
                    .onAppear { appState.activeCampaign = campaign }
            }
            .alert(
                "Delete Campaign?",
                isPresented: Binding(
                    get: { campaignToDelete != nil },
                    set: { if !$0 { campaignToDelete = nil } }
                ),
                presenting: campaignToDelete
            ) { campaign in
                Button("Delete", role: .destructive) {
                    modelContext.delete(campaign)
                    campaignToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    campaignToDelete = nil
                }
            } message: { campaign in
                Text("\(campaign.name) and all its loot will be permanently deleted.")
            }
        }
    }

    private func confirmDelete(at offsets: IndexSet) {
        campaignToDelete = offsets.map { campaigns[$0] }.first
    }
}

struct CampaignRowView: View {
    let campaign: Campaign

    var body: some View {
        VStack(alignment: .leading) {
            Text(campaign.name)
                .font(.headline)
            Text("\((campaign.loot?.count ?? 0).formatted(.number)) items")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
