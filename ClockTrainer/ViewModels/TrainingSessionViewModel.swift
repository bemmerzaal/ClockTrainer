import Foundation
import SwiftUI

final class TrainingSessionViewModel: ObservableObject {
    struct Feedback: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let isPositive: Bool
    }

    @Published private(set) var questions: [ClockQuestion]
    @Published private(set) var currentQuestionIndex: Int = 0
    @Published private(set) var score: Int = 0
    @Published private(set) var correctCount: Int = 0
    @Published private(set) var streak: Int = 0
    @Published private(set) var earnedBadges: [ClockBadge] = []
    @Published private(set) var isCompleted: Bool = false
    @Published var activeBadge: ClockBadge?
    @Published var feedback: Feedback?

    let level: ClockLevel

    init(level: ClockLevel) {
        self.level = level
        self.questions = TrainingSessionViewModel.generateQuestions(for: level)
    }

    var currentQuestion: ClockQuestion? {
        guard questions.indices.contains(currentQuestionIndex) else { return nil }
        return questions[currentQuestionIndex]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(questions.count)
    }

    func submit(answer: ClockSubmittedAnswer) {
        guard let question = currentQuestion, !isCompleted else { return }

        let isCorrect: Bool
        switch (question.kind, answer) {
        case (_, .option(let option)):
            isCorrect = option.id == question.correctOption?.id
        case (.setAnalog, .time(let time)), (.setDigital, .time(let time)):
            if let correct = question.correctTime {
                isCorrect = time.isApproximatelyEqual(to: correct, toleranceMinutes: 1)
            } else {
                isCorrect = false
            }
        case (.dayPart, .dayPart(let part)):
            isCorrect = part == question.correctDayPart
        case (.elapsed, .elapsedMinutes(let minutes)):
            isCorrect = minutes == question.correctElapsedMinutes
        default:
            isCorrect = false
        }

        if isCorrect {
            streak += 1
            correctCount += 1
            let bonus = max(0, streak - 1) * 10
            score += 100 + bonus
            feedback = Feedback(title: "Goed gedaan!", message: succesMessage(for: question), isPositive: true)
            if question.isCheckpoint {
                let badge = badgeFor(question: question)
                if !earnedBadges.contains(where: { $0.title == badge.title }) {
                    earnedBadges.append(badge)
                    activeBadge = badge
                }
            }
        } else {
            streak = 0
            feedback = Feedback(title: "Oeps!", message: correctionMessage(for: question), isPositive: false)
        }

        advance()
    }

    func makeResult() -> TrainingSessionResult {
        TrainingSessionResult(
            level: level,
            score: score,
            correctCount: correctCount,
            totalQuestions: questions.count,
            earnedBadges: earnedBadges
        )
    }

    private func advance() {
        let nextIndex = currentQuestionIndex + 1
        if nextIndex >= questions.count {
            isCompleted = true
        } else {
            currentQuestionIndex = nextIndex
        }
    }

    private func succesMessage(for question: ClockQuestion) -> String {
        switch question.concept {
        case .hours: return "Je herkent de uren al heel goed!"
        case .halfHours: return "Halve uurtjes zijn een eitje."
        case .quarterHours: return "Kwartieren afronden gaat super!"
        case .minutes: return "Elke minuut telt en jij weet ze te vinden!"
        case .seconds: return "Zelfs seconden hebben geen geheimen."
        case .dayParts: return "Je weet precies welk deel van de dag het is!"
        case .reading: return "Je leest de klok als een pro."
        case .setting: return "Je stelt de klok perfect in."
        case .elapsed: return "Je kunt tijdverschillen berekenen!"
        }
    }

    private func correctionMessage(for question: ClockQuestion) -> String {
        switch question.kind {
        case .analogToDigital:
            return "Kijk goed naar de kleine en grote wijzer. Probeer het nog eens!"
        case .digitalToAnalog:
            return "Let op de minuten: waar wijst de grote wijzer?"
        case .setAnalog:
            return "Versleep de wijzers naar het juiste uur en minuten."
        case .setDigital:
            return "Typ precies wat je op de klok ziet."
        case .dayPart:
            return "Denk aan wat je op dat moment van de dag doet."
        case .elapsed:
            return "Tel de minuten en uren rustig op."
        }
    }

    private func badgeFor(question: ClockQuestion) -> ClockBadge {
        switch question.concept {
        case .hours, .halfHours:
            return ClockBadge(title: "Uur Held", description: "Je beheerst het lezen van uren!", systemImage: "clock.circle", gradient: [.blue, .teal])
        case .minutes, .quarterHours, .seconds:
            return ClockBadge(title: "Minuten Meester", description: "Je beheerst minuten en seconden!", systemImage: "timer", gradient: [.green, .yellow])
        case .dayParts:
            return ClockBadge(title: "Dagdeel Detective", description: "Je kent de dag van ochtend tot nacht!", systemImage: "sun.max", gradient: [.orange, .pink])
        case .reading:
            return ClockBadge(title: "Lees Kampioen", description: "Analoge en digitale tijden lees je perfect!", systemImage: "text.book.closed", gradient: [.purple, .blue])
        case .setting:
            return ClockBadge(title: "Klok Bouwer", description: "Je stelt de klok supersnel in!", systemImage: "hand.draw", gradient: [.mint, .cyan])
        case .elapsed:
            return ClockBadge(title: "Tijd Rekenkundige", description: "Je berekent tijdsverschillen moeiteloos!", systemImage: "brain.head.profile", gradient: [.indigo, .blue])
        }
    }
}

private extension TrainingSessionViewModel {
    static func generateQuestions(for level: ClockLevel) -> [ClockQuestion] {
        var questions: [ClockQuestion] = []
        let checkpointSet = Set(level.checkpoints)
        for index in 0..<level.questionCount {
            let isCheckpoint = checkpointSet.contains(index)
            let concept = level.focusConcepts.randomElement() ?? .hours
            let kind = selectKind(for: concept, difficulty: level.difficulty)
            switch kind {
            case .analogToDigital:
                questions.append(makeAnalogToDigitalQuestion(concept: concept, difficulty: level.difficulty, isCheckpoint: isCheckpoint))
            case .digitalToAnalog:
                questions.append(makeDigitalToAnalogQuestion(concept: concept, difficulty: level.difficulty, isCheckpoint: isCheckpoint))
            case .setAnalog:
                questions.append(makeSetAnalogQuestion(concept: concept, difficulty: level.difficulty, isCheckpoint: isCheckpoint))
            case .setDigital:
                questions.append(makeSetDigitalQuestion(concept: concept, difficulty: level.difficulty, isCheckpoint: isCheckpoint))
            case .dayPart:
                questions.append(makeDayPartQuestion(isCheckpoint: isCheckpoint))
            case .elapsed:
                questions.append(makeElapsedQuestion(difficulty: level.difficulty, isCheckpoint: isCheckpoint))
            }
        }
        return questions
    }

    static func selectKind(for concept: ClockConcept, difficulty: Int) -> ClockQuestionKind {
        switch concept {
        case .hours, .halfHours, .reading:
            return difficulty > 1 ? [.analogToDigital, .digitalToAnalog].randomElement() ?? .analogToDigital : .analogToDigital
        case .minutes, .quarterHours:
            return difficulty > 1 ? [.analogToDigital, .setDigital].randomElement() ?? .analogToDigital : .analogToDigital
        case .seconds:
            return .setDigital
        case .setting:
            return [.setAnalog, .setDigital].randomElement() ?? .setAnalog
        case .dayParts:
            return .dayPart
        case .elapsed:
            return .elapsed
        }
    }

    static func makeAnalogToDigitalQuestion(concept: ClockConcept, difficulty: Int, isCheckpoint: Bool) -> ClockQuestion {
        let time = randomTime(step: difficulty == 1 ? 30 : (difficulty == 2 ? 15 : 5), includeSeconds: difficulty >= 2)
        let correct = ClockQuestion.Option(text: time.digitalString, emoji: "✅", time: time)
        let distractors = generateDistractors(for: time, count: 3, step: difficulty == 1 ? 30 : 5)
        let options = ( [correct] + distractors ).shuffled()
        return ClockQuestion(
            kind: .analogToDigital,
            prompt: "Welke digitale tijd hoort bij deze klok?",
            detail: "Let op de grote en kleine wijzer.",
            targetTime: time,
            options: options,
            correctOption: correct,
            correctTime: nil,
            correctDayPart: nil,
            correctElapsedMinutes: nil,
            concept: concept,
            isCheckpoint: isCheckpoint
        )
    }

    static func makeDigitalToAnalogQuestion(concept: ClockConcept, difficulty: Int, isCheckpoint: Bool) -> ClockQuestion {
        let time = randomTime(step: difficulty == 1 ? 30 : 5, includeSeconds: false)
        let options = generateAnalogOptions(correct: time, count: 3, step: difficulty == 1 ? 30 : 10).shuffled()
        let correct = options.first { $0.time == time }
        return ClockQuestion(
            kind: .digitalToAnalog,
            prompt: "Welke klok laat \(time.digitalString) zien?",
            detail: "Kies de klok met de juiste wijzers.",
            targetTime: time,
            options: options,
            correctOption: correct,
            correctTime: nil,
            correctDayPart: nil,
            correctElapsedMinutes: nil,
            concept: concept,
            isCheckpoint: isCheckpoint
        )
    }

    static func makeSetAnalogQuestion(concept: ClockConcept, difficulty: Int, isCheckpoint: Bool) -> ClockQuestion {
        let time = randomTime(step: difficulty == 1 ? 15 : 5, includeSeconds: false)
        return ClockQuestion(
            kind: .setAnalog,
            prompt: "Zet de analoge klok goed!",
            detail: "Sleep de wijzers naar \(time.digitalString).",
            targetTime: time,
            options: [],
            correctOption: nil,
            correctTime: time,
            correctDayPart: nil,
            correctElapsedMinutes: nil,
            concept: concept,
            isCheckpoint: isCheckpoint
        )
    }

    static func makeSetDigitalQuestion(concept: ClockConcept, difficulty: Int, isCheckpoint: Bool) -> ClockQuestion {
        let time = randomTime(step: difficulty == 1 ? 15 : 1, includeSeconds: difficulty >= 3)
        return ClockQuestion(
            kind: .setDigital,
            prompt: "Vul de digitale tijd in.",
            detail: "Wat hoort bij deze klok?",
            targetTime: time,
            options: [],
            correctOption: nil,
            correctTime: time,
            correctDayPart: nil,
            correctElapsedMinutes: nil,
            concept: concept,
            isCheckpoint: isCheckpoint
        )
    }

    static func makeDayPartQuestion(isCheckpoint: Bool) -> ClockQuestion {
        let hour = Int.random(in: 0..<24)
        let time = ClockTime(hour: hour, minute: [0, 15, 30, 45].randomElement() ?? 0)
        let correctPart = DayPart.from(hour: hour)
        let options = DayPart.allCases.map { part in
            ClockQuestion.Option(text: part.rawValue, emoji: part == correctPart ? "🌟" : "", time: nil)
        }.shuffled()
        let correctOption = options.first { $0.text == correctPart.rawValue }
        return ClockQuestion(
            kind: .dayPart,
            prompt: "Welk dagdeel hoort bij \(time.digitalString)?",
            detail: correctPart.description,
            targetTime: time,
            options: options,
            correctOption: correctOption,
            correctTime: nil,
            correctDayPart: correctPart,
            correctElapsedMinutes: nil,
            concept: .dayParts,
            isCheckpoint: isCheckpoint
        )
    }

    static func makeElapsedQuestion(difficulty: Int, isCheckpoint: Bool) -> ClockQuestion {
        let start = randomTime(step: 15, includeSeconds: false)
        let additionalMinutes = difficulty >= 3 ? [35, 45, 50, 70].randomElement() ?? 45 : [15, 20, 30, 40].randomElement() ?? 20
        let endMinutes = (start.hour * 60 + start.minute + additionalMinutes) % (24 * 60)
        let end = ClockTime(hour: endMinutes / 60, minute: endMinutes % 60)
        let questionText = "Hoeveel minuten zitten er tussen \(start.digitalString) en \(end.digitalString)?"
        let correctMinutes = additionalMinutes
        let correct = ClockQuestion.Option(text: "\(correctMinutes) min", emoji: "🎯", time: nil)
        var options: [ClockQuestion.Option] = [correct]
        let alternatives = [correctMinutes - 10, correctMinutes + 5, correctMinutes + 15].filter { $0 > 0 }
        for alt in alternatives {
            options.append(ClockQuestion.Option(text: "\(alt) min", emoji: "", time: nil))
        }
        return ClockQuestion(
            kind: .elapsed,
            prompt: questionText,
            detail: "Tip: Tel eerst de uren en daarna de minuten. Eindtijd: \(end.digitalString)",
            targetTime: start,
            options: options.shuffled(),
            correctOption: correct,
            correctTime: nil,
            correctDayPart: nil,
            correctElapsedMinutes: correctMinutes,
            concept: .elapsed,
            isCheckpoint: isCheckpoint
        )
    }

    static func randomTime(step: Int, includeSeconds: Bool) -> ClockTime {
        let hour = Int.random(in: 6..<20)
        let minute: Int
        if step == 1 {
            minute = Int.random(in: 0..<60)
        } else {
            let possibilities = stride(from: 0, to: 60, by: step).map { Int($0) }
            minute = possibilities.randomElement() ?? 0
        }
        let second = includeSeconds ? [0, 10, 15, 20, 30, 45].randomElement() ?? 0 : 0
        return ClockTime(hour: hour, minute: minute, second: second)
    }

    static func generateDistractors(for time: ClockTime, count: Int, step: Int) -> [ClockQuestion.Option] {
        var options: [ClockQuestion.Option] = []
        var used: Set<String> = [time.digitalString]
        while options.count < count {
            let offset = Int.random(in: -2...2) * step
            let totalMinutes = time.hour * 60 + time.minute + offset
            let minutes = ((totalMinutes % (24 * 60)) + (24 * 60)) % (24 * 60)
            let candidate = ClockTime(hour: minutes / 60, minute: minutes % 60)
            if !used.contains(candidate.digitalString) {
                used.insert(candidate.digitalString)
                options.append(ClockQuestion.Option(text: candidate.digitalString, emoji: "", time: candidate))
            }
        }
        return options
    }

    static func generateAnalogOptions(correct: ClockTime, count: Int, step: Int) -> [ClockQuestion.Option] {
        var options: [ClockQuestion.Option] = [ClockQuestion.Option(text: "", emoji: "⭐️", time: correct)]
        while options.count < count {
            let offset = Int.random(in: -3...3) * step
            let minutes = ((correct.hour * 60 + correct.minute + offset) % (24 * 60) + (24 * 60)) % (24 * 60)
            let candidate = ClockTime(hour: minutes / 60, minute: minutes % 60)
            if !options.contains(where: { $0.time == candidate }) {
                options.append(ClockQuestion.Option(text: "", emoji: "", time: candidate))
            }
        }
        return options
    }
}
