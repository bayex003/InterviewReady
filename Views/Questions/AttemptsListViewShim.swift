import SwiftUI

/// Compatibility shim: some call sites use `AttemptListView` by mistake.
/// Keep this until all references are corrected.
struct AttemptsListView: View {
    @ObservedObject var attemptsStore: AttemptsStore

    var body: some View {
        AttemptsListView(attemptsStore: attemptsStore)
    }
}
