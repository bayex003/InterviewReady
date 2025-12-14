import SwiftUI

struct RootContentView: View {
    @State private var selectedTab: Tab = .home
    
    // Hide native tab bar so we can use our floating one
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content Area
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)
                
                Text("Jobs List Coming Soon")
                    .tag(Tab.jobs)
                
                Text("Questions Coming Soon")
                    .tag(Tab.questions)
                
                Text("Stories Coming Soon")
                    .tag(Tab.stories)
            }
            
            // The Floating Nav
            FloatingTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard) // Prevents tab bar from riding up on keyboard
    }
}
