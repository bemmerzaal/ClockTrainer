import Foundation
import SwiftUI
import Combine

struct LevelProgress: Identifiable {
    let id: UUID
    var bestScore: Int
    var lastPlayed: Date?
    var badges: [ClockBadge]
    var completedQuestions: Int
    var totalQuestions: Int

    init(level: ClockLevel) {
        self.id = level.id
        self.bestScore = 0
        self.lastPlayed = nil
        self.badges = []
        self.completedQuestions = 0
        self.totalQuestions = level.questionCount
    }
}

enum AdventureTheme {
    case sunrise
    case jungle
    case galaxy

    var gradient: LinearGradient {
        switch self {
        case .sunrise:
            return LinearGradient(colors: [.orange, .pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .jungle:
            return LinearGradient(colors: [.green, .teal, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .galaxy:
            return LinearGradient(colors: [.indigo, .purple, .black.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

final class AdventureViewModel: ObservableObject {
    @Published var profileName: String
    @Published private(set) var progressMap: [UUID: LevelProgress]
    let levels: [ClockLevel]

    init(levels: [ClockLevel] = ClockAdventure.levels) {
        self.levels = levels
        self.profileName = "Tijdreiziger"
        self.progressMap = Dictionary(uniqueKeysWithValues: levels.map { ($0.id, LevelProgress(level: $0)) })
    }

    func progress(for level: ClockLevel) -> LevelProgress {
        progressMap[level.id] ?? LevelProgress(level: level)
    }

    func updateProgress(with result: TrainingSessionResult) {
        var progress = progress(for: result.level)
        progress.bestScore = max(progress.bestScore, result.score)
        progress.completedQuestions = max(progress.completedQuestions, result.totalQuestions)
        progress.lastPlayed = Date()
        var badgeDictionary: [String: ClockBadge] = [:]
        for badge in progress.badges + result.earnedBadges {
            badgeDictionary[badge.title] = badge
        }
        progress.badges = Array(badgeDictionary.values)
        progressMap[result.level.id] = progress
    }

    func unlockedLevels() -> [ClockLevel] {
        var unlocked: [ClockLevel] = []
        for (index, level) in levels.enumerated() {
            if index == 0 {
                unlocked.append(level)
                continue
            }
            let previous = levels[index - 1]
            let progress = progressMap[previous.id] ?? LevelProgress(level: previous)
            if progress.bestScore >= previous.questionCount / 2 {
                unlocked.append(level)
            }
        }
        return unlocked
    }
}
