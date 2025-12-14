import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background Color (Matches your Sage brand)
            Color.sage500.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 1. The Logo
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    
                    Image(systemName: "briefcase.fill") // Or use Image("YourLogoAsset")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.sage500)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                }
                
                // 2. App Name
                Text("InterviewReady")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                // 3. Loading Indicator
                ProgressView()
                    .tint(.white)
                    .controlSize(.large)
                    .padding(.top, 20)
            }
        }
        .onAppear {
            // Subtle breathing animation for the logo
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
