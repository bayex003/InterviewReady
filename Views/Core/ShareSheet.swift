import SwiftUI
import UIKit

#if os(iOS)
public struct ShareSheet: UIViewControllerRepresentable {
    public typealias UIViewControllerType = UIActivityViewController

    public var items: [Any]
    public var applicationActivities: [UIActivity]? = nil
    public var excludedActivityTypes: [UIActivity.ActivityType]? = nil

    public init(
        items: [Any],
        applicationActivities: [UIActivity]? = nil,
        excludedActivityTypes: [UIActivity.ActivityType]? = nil
    ) {
        self.items = items
        self.applicationActivities = applicationActivities
        self.excludedActivityTypes = excludedActivityTypes
    }

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: applicationActivities
        )
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = { _, _, _, _ in
            // SwiftUI manages dismissal of the sheet.
        }
        return controller
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Intentionally no-op.
        // UIActivityViewController isn't designed to reliably update activity items after creation.
        // If the items change, recreate the sheet (see note below).
    }

    public func makeCoordinator() -> Coordinator { Coordinator() }

    public class Coordinator {}
}
#endif

