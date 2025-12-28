import SwiftUI

/// Compatibility wrapper.
/// The app previously had two “add application” screens:
/// - AddApplicationView (JobsStore/JobApplication)
/// - AddJobView (SwiftData Job)
/// We now keep ONE source of truth: SwiftData Job via AddJobView.

struct AddApplicationView: View {
    var body: some View {
        AddJobView()
    }
}
