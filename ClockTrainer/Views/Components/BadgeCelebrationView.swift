import SwiftUI

struct BadgeCelebrationView: View {
    var badge: ClockBadge
    var dismissAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 16) {
                LinearGradient(colors: badge.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .mask(
                        Image(systemName: badge.systemImage)
                            .resizable()
                            .scaledToFit()
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .white.opacity(0.5), radius: 12, x: 0, y: 4)

                Text(badge.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(badge.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.9))

                Button(action: dismissAction) {
                    Text("Hoera!")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.2), in: Capsule())
                        .foregroundStyle(.white)
                }
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(LinearGradient(colors: badge.gradient, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
            )
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.55).ignoresSafeArea())
        .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
    BadgeCelebrationView(badge: ClockAdventure.badgeExplorer) {}
}
