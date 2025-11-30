import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var proManager: ProAccessManager

    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Text("Dark mode is default for now.")
                    .foregroundColor(.secondary)
            }

            Section(header: Text("InterviewReady Pro"), footer: Text("Toggle to simulate unlock during development.")) {
                Toggle("Pro unlocked", isOn: $proManager.isProUnlocked)
                NavigationLink("View Paywall") {
                    PaywallView()
                }
            }

            Section(header: Text("About")) {
                Text("InterviewReady v1.0")
                Text("Offline-first, privacy-friendly interview prep.")
            }
        }
        .navigationTitle("Settings")
    }
}
