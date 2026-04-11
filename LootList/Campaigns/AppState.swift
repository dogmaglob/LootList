import SwiftUI

/// Holds app-wide session state. Injected into the environment at the root
/// and read by any view that needs to scope data to the active campaign.
@Observable
@MainActor
final class AppState {
    var activeCampaign: Campaign?

    init(activeCampaign: Campaign? = nil) {
        self.activeCampaign = activeCampaign
    }
}
