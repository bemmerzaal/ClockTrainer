import SwiftUI

struct LevelCardView: View {
    let level: ClockLevel
    let progress: LevelProgress
    var locked: Bool
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Text(level.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                VStack(spacing: 6) {
                    Image(systemName: locked ? "lock.fill" : level.badge.systemImage)
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                    Text("Level \(level.difficulty)")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundStyle(.white)
                }
            }

            HStack(spacing: 8) {
                ForEach(level.focusConcepts, id: \.id) { concept in
                    Text(concept.localizedTitle)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.2), in: Capsule())
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(progressDescription)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                ProgressView(value: min(progressValue, 1.0))
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(x: 1, y: 1.2, anchor: .center)
                    .background(.white.opacity(0.15), in: Capsule())
            }

            Button(action: action) {
                HStack {
                    Text(locked ? "Speel eerst vorige level" : "Start missie")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
                .padding()
                .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .foregroundStyle(.white)
            }
            .disabled(locked)
            .opacity(locked ? 0.6 : 1)
        }
        .padding()
        .background(
            LinearGradient(colors: level.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.white.opacity(0.08))
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 12)
    }

    private var progressValue: Double {
        guard progress.totalQuestions > 0 else { return 0 }
        return Double(progress.bestScore) / Double(progress.totalQuestions * 100)
    }

    private var progressDescription: String {
        if progress.bestScore == 0 {
            return "Nog niet gespeeld."
        }
        return "Beste score: \(progress.bestScore)" + " | Badges: \(progress.badges.count)"
    }
}

#Preview {
    LevelCardView(level: ClockAdventure.levels[0], progress: LevelProgress(level: ClockAdventure.levels[0]), locked: false) {}
        .padding()
}
