import SwiftUI

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50) { _ in
                ConfettiParticle()
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ConfettiParticle: View {
    @State private var location: CGPoint = CGPoint(x: CGFloat.random(in: 0...UIScreen.main.bounds.width), y: -100)
    @State private var rotation: Double = Double.random(in: 0...360)
    
    // Random colors including your brand colors
    let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, Color.sage500]
    
    var body: some View {
        Rectangle()
            .fill(colors.randomElement()!)
            .frame(width: 10, height: 10)
            .position(location)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.easeOut(duration: Double.random(in: 1.5...3.0)).repeatCount(1, autoreverses: false)) {
                    location.y = UIScreen.main.bounds.height + 100
                    rotation += Double.random(in: 180...720)
                }
            }
    }
}
