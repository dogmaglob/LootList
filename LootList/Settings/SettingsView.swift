import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section {
                NavigationLink("Categories") {
                    CategoryManagerView()
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
