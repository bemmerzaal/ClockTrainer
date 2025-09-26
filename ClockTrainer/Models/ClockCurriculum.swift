import Foundation
import SwiftUI

struct ClockTime: Equatable, Hashable {
    var hour: Int
    var minute: Int
    var second: Int

    init(hour: Int, minute: Int, second: Int = 0) {
        self.hour = hour
        self.minute = minute
        self.second = second
        normalize()
    }

    private mutating func normalize() {
        var totalSeconds = hour * 3600 + minute * 60 + second
        let secondsPerDay = 24 * 3600
        totalSeconds = ((totalSeconds % secondsPerDay) + secondsPerDay) % secondsPerDay
        hour = totalSeconds / 3600
        minute = (totalSeconds % 3600) / 60
        second = totalSeconds % 60
    }

    var twelveHourValue: Int {
        let modHour = hour % 12
        return modHour == 0 ? 12 : modHour
    }

    var digitalString: String {
        String(format: "%02d:%02d", hour, minute)
    }

    var spokenString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "HH:mm"
        if let date = formatter.date(from: digitalString) {
            formatter.dateFormat = "HH:mm 'uur'"
            return formatter.string(from: date)
        }
        return "\(digitalString) uur"
    }

    var hourAngle: Angle {
        let total = Double(hour % 12) + Double(minute) / 60 + Double(second) / 3600
        return Angle(degrees: total / 12 * 360)
    }

    var minuteAngle: Angle {
        let total = Double(minute) + Double(second) / 60
        return Angle(degrees: total / 60 * 360)
    }

    var secondAngle: Angle {
        Angle(degrees: Double(second) / 60 * 360)
    }

    func isApproximatelyEqual(to other: ClockTime, toleranceMinutes: Int = 1) -> Bool {
        let lhs = hour * 60 + minute
        let rhs = other.hour * 60 + other.minute
        return abs(lhs - rhs) <= toleranceMinutes
    }
}

enum DayPart: String, CaseIterable, Identifiable {
    case morning = "Ochtend"
    case afternoon = "Middag"
    case evening = "Avond"
    case night = "Nacht"

    var id: String { rawValue }

    var timeRange: ClosedRange<Int> {
        switch self {
        case .morning:
            return 6...11
        case .afternoon:
            return 12...17
        case .evening:
            return 18...21
        case .night:
            return 22...23
        }
    }

    static func from(hour: Int) -> DayPart {
        for part in DayPart.allCases {
            if part.timeRange.contains(hour) {
                return part
            }
        }
        return hour < 6 ? .night : .morning
    }

    var description: String {
        switch self {
        case .morning:
            return "De zon komt op en je ontbijt."
        case .afternoon:
            return "Je speelt na school of luncht."
        case .evening:
            return "Avondeten en gezellig samen."
        case .night:
            return "Tijd om te slapen onder de sterren."
        }
    }

    var gradient: [Color] {
        switch self {
        case .morning:
            return [.orange, .yellow]
        case .afternoon:
            return [.mint, .green]
        case .evening:
            return [.purple, .pink]
        case .night:
            return [.blue, .indigo]
        }
    }
}

enum ClockConcept: String, CaseIterable, Identifiable {
    case seconds
    case minutes
    case quarterHours
    case halfHours
    case hours
    case dayParts
    case reading
    case setting
    case elapsed

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .seconds: return "Seconden"
        case .minutes: return "Minuten"
        case .quarterHours: return "Kwartieren"
        case .halfHours: return "Half uren"
        case .hours: return "Uren"
        case .dayParts: return "Dagdelen"
        case .reading: return "Klok lezen"
        case .setting: return "Klok instellen"
        case .elapsed: return "Tijd tussen"
        }
    }
}

struct ClockBadge: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let systemImage: String
    let gradient: [Color]
}

struct ClockLevel: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let gradient: [Color]
    let focusConcepts: [ClockConcept]
    let questionCount: Int
    let checkpoints: [Int]
    let badge: ClockBadge
    let difficulty: Int
}

extension ClockLevel: Hashable {
    static func == (lhs: ClockLevel, rhs: ClockLevel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum ClockQuestionKind {
    case analogToDigital
    case digitalToAnalog
    case setAnalog
    case setDigital
    case dayPart
    case elapsed
}

struct ClockQuestion: Identifiable {
    struct Option: Identifiable, Hashable {
        let id = UUID()
        let text: String
        let emoji: String
        let time: ClockTime?
    }

    let id = UUID()
    let kind: ClockQuestionKind
    let prompt: String
    let detail: String
    let targetTime: ClockTime?
    let options: [Option]
    let correctOption: Option?
    let correctTime: ClockTime?
    let correctDayPart: DayPart?
    let correctElapsedMinutes: Int?
    let concept: ClockConcept
    let isCheckpoint: Bool
}

enum ClockSubmittedAnswer {
    case option(ClockQuestion.Option)
    case time(ClockTime)
    case dayPart(DayPart)
    case elapsedMinutes(Int)
}

struct TrainingSessionResult {
    let level: ClockLevel
    let score: Int
    let correctCount: Int
    let totalQuestions: Int
    let earnedBadges: [ClockBadge]
}

struct ClockAdventure {
    static let badgeExplorer = ClockBadge(
        title: "Tijd Verkenner",
        description: "Je hebt de basis van analoge en digitale tijden ontdekt!",
        systemImage: "clock",
        gradient: [.blue, .purple]
    )

    static let badgeStrategist = ClockBadge(
        title: "Planning Pro",
        description: "Je kunt kloktijden instellen als een echte planner.",
        systemImage: "calendar",
        gradient: [.pink, .orange]
    )

    static let badgeAstronaut = ClockBadge(
        title: "Sterrenwachter",
        description: "Je kent alle dagdelen, van ochtendgloren tot middernacht!",
        systemImage: "moon.stars",
        gradient: [.indigo, .black.opacity(0.8)]
    )

    static let levels: [ClockLevel] = [
        ClockLevel(
            title: "Klok Eiland",
            subtitle: "Leer de basis van uren en halve uren.",
            gradient: [.blue, .teal],
            focusConcepts: [.hours, .halfHours, .reading],
            questionCount: 8,
            checkpoints: [4],
            badge: badgeExplorer,
            difficulty: 1
        ),
        ClockLevel(
            title: "Minuten Jungle",
            subtitle: "Ontdek kwartieren, minuten en seconden.",
            gradient: [.green, .yellow],
            focusConcepts: [.minutes, .quarterHours, .seconds, .setting],
            questionCount: 10,
            checkpoints: [5, 9],
            badge: badgeStrategist,
            difficulty: 2
        ),
        ClockLevel(
            title: "Dagdeel Ruimte",
            subtitle: "Plan je dag van ochtend tot nacht.",
            gradient: [.purple, .blue],
            focusConcepts: [.dayParts, .elapsed, .reading, .setting],
            questionCount: 12,
            checkpoints: [6, 11],
            badge: badgeAstronaut,
            difficulty: 3
        )
    ]
}
