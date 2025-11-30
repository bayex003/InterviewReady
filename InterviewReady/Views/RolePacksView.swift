import SwiftUI

struct RolePacksView: View {
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var proManager: ProAccessManager
    @StateObject private var viewModel = RolePacksViewModel()

    var body: some View {
        List {
            ForEach(viewModel.availablePacks(in: dataStore)) { pack in
                NavigationLink(destination: destination(for: pack)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pack.name)
                                .font(.headline)
                            Text(pack.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        TagChipView(text: pack.isProOnly ? "Pro" : "Free", color: pack.isProOnly ? .yellow : .irMint)
                    }
                }
            }
        }
        .navigationTitle("Role Packs")
    }

    @ViewBuilder
    private func destination(for pack: RolePack) -> some View {
        if pack.isProOnly && !proManager.isProUnlocked {
            PaywallView()
        } else {
            RolePackDetailView(pack: pack)
        }
    }
}
