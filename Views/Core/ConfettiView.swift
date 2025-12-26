import SwiftUI

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                ForEach(0..<50, id: \.self) { _ in
                    ConfettiParticle(containerSize: size)
                }
            }
            .onAppear {
                animate = true
            }
            .frame(width: size.width, height: size.height, alignment: .center)
        }
    }
}

struct ConfettiParticle: View {
    let containerSize: CGSize
    
    @State private var location: CGPoint
    @State private var rotation: Double = Double.random(in: 0...360)
    
    // Random colors including your brand colors
    let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, Color.sage500]
    
    init(containerSize: CGSize) {
        self.containerSize = containerSize
        // Initialize starting point using the provided container width, not UIScreen.main
        _location = State(initialValue: CGPoint(x: CGFloat.random(in: 0...containerSize.width), y: -100))
    }
    
    var body: some View {
        Rectangle()
            .fill(colors.randomElement()!)
            .frame(width: 10, height: 10)
            .position(location)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.easeOut(duration: Double.random(in: 1.5...3.0)).repeatCount(1, autoreverses: false)) {
                    // Animate to beyond the bottom of the current container
                    location.y = containerSize.height + 100
                    rotation += Double.random(in: 180...720)
                }
            }
    }
}
