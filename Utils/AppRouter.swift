import Foundation
import Combine

final class AppRouter: ObservableObject {
    @Published var presentAddJob: Bool = false
    @Published var presentAddMoment: Bool = false

    // NEW: hide floating tab bar on pushed screens
    @Published var isTabBarHidden: Bool = false
}
