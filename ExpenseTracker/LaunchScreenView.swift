import SwiftUI

// MARK: - Launch Screen

struct LaunchScreenView: View {
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0
    @State private var logoRotation: Double = -15
    @State private var glowOpacity: Double = 0

    let onFinish: () -> Void

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "0D1B2A") ?? .black,
                    Color(hex: "1A3A4A") ?? .black,
                    Color(hex: "0A2030") ?? .black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Ambient glow blobs
            ZStack {
                Circle()
                    .fill(Color(hex: "4F8EF7")?.opacity(0.18) ?? .clear)
                    .frame(width: 340)
                    .blur(radius: 100)
                    .offset(x: -80, y: -200)
                    .opacity(glowOpacity)

                Circle()
                    .fill(Color(hex: "2EC4B6")?.opacity(0.14) ?? .clear)
                    .frame(width: 280)
                    .blur(radius: 80)
                    .offset(x: 120, y: 260)
                    .opacity(glowOpacity)
            }
            .animation(.easeInOut(duration: 1.2).delay(0.3), value: glowOpacity)

            VStack(spacing: 28) {
                Spacer()

                // App icon mark
                ZStack {
                    // Outer glow ring
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color(hex: "4F8EF7") ?? .blue, Color(hex: "2EC4B6") ?? .teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 128, height: 128)
                        .opacity(0.5)
                        .scaleEffect(scale * 1.15)

                    // App icon from asset catalog
                    Image("AppLogo")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: (Color(hex: "4F8EF7") ?? .blue).opacity(0.55), radius: 36, y: 14)
                        .rotationEffect(.degrees(logoRotation))
                }
                .scaleEffect(scale)
                .opacity(opacity)

                // App name
                VStack(spacing: 8) {
                    Text("ExpenseTracker")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                        .opacity(opacity)

                    Text("Your money, beautifully organised")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.55))
                        .opacity(opacity)
                }

                Spacer()
            }
        }
        .onAppear {
            // Animate in
            withAnimation(.spring(duration: 0.8, bounce: 0.4)) {
                scale = 1
                opacity = 1
                logoRotation = 0
            }
            withAnimation(.easeInOut(duration: 1.2).delay(0.2)) {
                glowOpacity = 1
            }

            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    opacity = 0
                    scale = 1.06
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    onFinish()
                }
            }
        }
    }
}
