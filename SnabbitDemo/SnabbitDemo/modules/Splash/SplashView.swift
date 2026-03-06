import SwiftUI

struct SplashView: View {
    // Drives the entrance animation
    @State private var logoOpacity: Double = 0
    @State private var logoScale: Double = 0.85

    var body: some View {
        ZStack {
            // Same gradient as the break screen for a seamless brand feel
            LinearGradient(
                colors: [.breakGradientTop, .breakGradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                // App name
                Text("SnabbitDemo")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.8)))
                    .scaleEffect(1.2)
            }
            .opacity(logoOpacity)
            .scaleEffect(logoScale)
            .onAppear {
                withAnimation(.easeOut(duration: 0.45)) {
                    logoOpacity = 1
                    logoScale = 1
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
