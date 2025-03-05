import SwiftUI

struct AudioWaveAnimation: View {
    let isPlaying: Bool
    var onTap: () -> Void
    var color: Color = .brandMint
    
    // Configuration
    private let barCount = 9
    private let spacing: CGFloat = 2.5
    private let cornerRadius: CGFloat = 2
    private let minBarHeight: CGFloat = 3
    private let maxBarHeight: CGFloat = 20
    private let barWidth: CGFloat = 2.5
    
    // Different animation durations for variety
    private let animationDurations: [Double] = [0.7, 0.8, 0.9, 1.0, 0.75, 0.85, 0.95, 0.7, 0.8]
    
    @State private var heights: [CGFloat]
    
    init(isPlaying: Bool, color: Color = .brandMint, onTap: @escaping () -> Void) {
        self.isPlaying = isPlaying
        self.color = color
        self.onTap = onTap
        
        // Initialize with a wave-like pattern
        let initialHeights = [
            minBarHeight + 2,
            minBarHeight + 5,
            minBarHeight + 10,
            minBarHeight + 15,
            maxBarHeight,
            minBarHeight + 15,
            minBarHeight + 10,
            minBarHeight + 5,
            minBarHeight + 2
        ]
        _heights = State(initialValue: initialHeights.count == barCount ? 
                         initialHeights : Array(repeating: minBarHeight, count: barCount))
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Play/pause button
            Button(action: onTap) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(color)
            }
            .padding(.trailing, 10)
            
            // Audio wave bars
            HStack(alignment: .center, spacing: spacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(color)
                        .frame(width: barWidth, height: heights[index])
                }
            }
            .frame(height: maxBarHeight)
            .opacity(isPlaying ? 1.0 : 0.5)
        }
        .onAppear {
            if isPlaying {
                startAnimation()
            } else {
                resetToWavePattern(animated: false)
            }
        }
        .onChange(of: isPlaying) { oldValue, newValue in
            if newValue {
                startAnimation()
            } else {
                resetToWavePattern(animated: true)
            }
        }
    }
    
    private func startAnimation() {
        // Only animate if playing
        guard isPlaying else { return }
        
        // Animate each bar with a different pattern
        for i in 0..<barCount {
            // Create a wave-like pattern with different heights
            let baseHeight = maxBarHeight * 0.6
            let amplitude = maxBarHeight * 0.4
            let phase = Double(i) / Double(barCount) * 2 * .pi
            
            // Continuously animate between different heights
            withAnimation(
                Animation.easeInOut(duration: animationDurations[i % animationDurations.count])
                    .repeatForever(autoreverses: true)
                    .delay(Double(i) * 0.05)
            ) {
                // Calculate a height that follows a sine wave pattern
                let targetHeight = baseHeight + amplitude * sin(phase)
                heights[i] = max(minBarHeight, CGFloat(targetHeight))
            }
        }
    }
    
    private func resetToWavePattern(animated: Bool) {
        let wavePattern = [
            minBarHeight + 2,
            minBarHeight + 5,
            minBarHeight + 10,
            minBarHeight + 15,
            maxBarHeight * 0.7,
            minBarHeight + 15,
            minBarHeight + 10,
            minBarHeight + 5,
            minBarHeight + 2
        ]
        
        for i in 0..<barCount {
            if animated {
                withAnimation(.easeOut(duration: 0.3)) {
                    heights[i] = i < wavePattern.count ? wavePattern[i] : minBarHeight
                }
            } else {
                heights[i] = i < wavePattern.count ? wavePattern[i] : minBarHeight
            }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        AudioWaveAnimation(isPlaying: true) {}
        AudioWaveAnimation(isPlaying: false) {}
    }
    .padding()
    .background(Color.black)
} 