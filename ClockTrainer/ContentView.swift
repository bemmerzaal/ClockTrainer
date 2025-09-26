import SwiftUI

struct ContentView: View {
    @StateObject private var adventure = AdventureViewModel()
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AdventureTheme.galaxy.gradient
                    .ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        heroCard
                        badgeSection
                        levelSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 32)
                }
            }
            .navigationTitle("Clock Trainer")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: ClockLevel.self) { level in
                TrainingSessionView(level: level) { result in
                    adventure.updateProgress(with: result)
                }
            }
        }
    }

    private var heroCard: some View {
        let unlocked = adventure.unlockedLevels().count
        let bestScore = adventure.progressMap.values.map(\.bestScore).max() ?? 0
        let badgeCount = uniqueBadges.count

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hallo, \(adventure.profileName)!")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Klaar om met de tijd te spelen?")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 16) {
                statPill(title: "Badges", value: "\(badgeCount)", icon: "rosette")
                statPill(title: "Beste score", value: "\(bestScore)", icon: "medal")
                statPill(title: "Levels", value: "\(unlocked)/\(adventure.levels.count)", icon: "map")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [.purple.opacity(0.9), .blue.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 25, x: 0, y: 18)
    }

    private var badgeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Verzamelde badges")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if uniqueBadges.isEmpty {
                    Text("Maak de eerste missie af!")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(uniqueBadges, id: \.title) { badge in
                        badgeTile(for: badge)
                    }
                    if uniqueBadges.isEmpty {
                        badgeTile(for: ClockAdventure.badgeExplorer)
                            .opacity(0.3)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private var levelSection: some View {
        let unlockedIDs = Set(adventure.unlockedLevels().map(\.id))
        return VStack(alignment: .leading, spacing: 20) {
            Text("Kies je missie")
                .font(.title2.bold())
                .foregroundStyle(.white)

            ForEach(adventure.levels) { level in
                let progress = adventure.progress(for: level)
                let locked = !unlockedIDs.contains(level.id)
                LevelCardView(level: level, progress: progress, locked: locked) {
                    guard !locked else { return }
                    path.append(level)
                }
                .opacity(locked ? 0.7 : 1)
                .animation(.spring(), value: adventure.progressMap[level.id]?.bestScore ?? 0)
            }
        }
    }

    private var uniqueBadges: [ClockBadge] {
        var dictionary: [String: ClockBadge] = [:]
        for progress in adventure.progressMap.values {
            for badge in progress.badges {
                dictionary[badge.title] = badge
            }
        }
        return Array(dictionary.values).sorted { $0.title < $1.title }
    }

    private func statPill(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.headline)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func badgeTile(for badge: ClockBadge) -> some View {
        VStack(spacing: 8) {
            LinearGradient(colors: badge.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .mask(
                    Image(systemName: badge.systemImage)
                        .resizable()
                        .scaledToFit()
                )
                .frame(width: 64, height: 64)
            Text(badge.title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
        }
        .padding()
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

#Preview {
    ContentView()
}
