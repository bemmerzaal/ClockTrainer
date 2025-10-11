import SwiftUI

struct TrainingSessionView: View {
    let level: ClockLevel
    var onComplete: (TrainingSessionResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TrainingSessionViewModel

    @State private var selectedOptionID: UUID?
    @State private var analogHour: Int = 6
    @State private var analogMinute: Int = 0
    @State private var digitalHour: Int = 6
    @State private var digitalMinute: Int = 0
    @State private var showCompletion: Bool = false

    init(level: ClockLevel, onComplete: @escaping (TrainingSessionResult) -> Void) {
        self.level = level
        self.onComplete = onComplete
        _viewModel = State(wrappedValue: TrainingSessionViewModel(level: level))
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: level.gradient + [.black.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            content
            if let badge = viewModel.activeBadge {
                BadgeCelebrationView(badge: badge) {
                    withAnimation {
                        viewModel.activeBadge = nil
                    }
                }
            }
            if showCompletion {
                completionView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(level.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Stop") { dismiss() }
                    .foregroundStyle(.white)
            }
        }
        .onChange(of: viewModel.currentQuestionIndex) { _ in
            resetInputs()
        }
        .onChange(of: viewModel.isCompleted) { completed in
            if completed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation { showCompletion = true }
                }
            }
        }
    }

    private var content: some View {
        VStack(spacing: 24) {
            header
            if let question = viewModel.currentQuestion {
                questionCard(for: question)
            } else {
                Spacer()
            }
            if let feedback = viewModel.feedback {
                feedbackView(feedback)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Score \(viewModel.score)")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("Streak: \(viewModel.streak)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Vraag \(viewModel.currentQuestionIndex + 1) / \(viewModel.questions.count)")
                        .font(.headline)
                        .foregroundStyle(.white)
                    ProgressView(value: Double(viewModel.currentQuestionIndex), total: Double(max(viewModel.questions.count, 1)))
                        .progressViewStyle(.linear)
                        .tint(.white)
                        .frame(width: 140)
                }
            }
            .padding()
            .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    @ViewBuilder
    private func questionCard(for question: ClockQuestion) -> some View {
        VStack(spacing: 20) {
            Text(question.prompt)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            Text(question.detail)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))

            switch question.kind {
            case .analogToDigital:
                if let target = question.targetTime {
                    AnalogClockView(time: target, showSeconds: level.difficulty >= 2, accentColor: .white)
                        .frame(height: 220)
                }
                optionGrid(for: question)
            case .digitalToAnalog:
                if let target = question.targetTime {
                    DigitalClockDisplay(time: target, label: "Zoek deze tijd", accentColor: .pink)
                }
                analogOptions(for: question)
            case .setAnalog:
                setAnalogView(target: question.targetTime)
            case .setDigital:
                setDigitalView(target: question.targetTime)
            case .dayPart:
                if let target = question.targetTime {
                    DigitalClockDisplay(time: target, label: "Welke dagdeel?", accentColor: .purple)
                }
                dayPartOptions(for: question)
            case .elapsed:
                timelineView(for: question)
                optionGrid(for: question)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
    }

    @ViewBuilder
    private func optionGrid(for question: ClockQuestion) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(question.options) { option in
                Button {
                    selectedOptionID = option.id
                    withAnimation {
                        viewModel.submit(answer: .option(option))
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(option.text)
                            .font(.headline)
                        if !option.emoji.isEmpty {
                            Text(option.emoji)
                                .font(.largeTitle)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedOptionID == option.id ? Color.white.opacity(0.3) : Color.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .foregroundStyle(.white)
                }
            }
        }
    }

    @ViewBuilder
    private func analogOptions(for question: ClockQuestion) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(question.options) { option in
                Button {
                    selectedOptionID = option.id
                    if let optionTime = option.time {
                        withAnimation {
                            viewModel.submit(answer: .option(option))
                        }
                    }
                } label: {
                    AnalogClockView(time: option.time ?? question.targetTime ?? ClockTime(hour: 6, minute: 0), accentColor: .white)
                        .frame(height: 140)
                        .padding(12)
                        .background(selectedOptionID == option.id ? Color.white.opacity(0.35) : Color.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
        }
    }

    @ViewBuilder
    private func dayPartOptions(for question: ClockQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(question.options) { option in
                Button {
                    selectedOptionID = option.id
                    if let part = DayPart(rawValue: option.text) {
                        withAnimation {
                            viewModel.submit(answer: .dayPart(part))
                        }
                    }
                } label: {
                    HStack {
                        Text(option.text)
                            .font(.headline)
                        Spacer()
                        Text(option.emoji)
                            .font(.title2)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedOptionID == option.id ? Color.white.opacity(0.3) : Color.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .foregroundStyle(.white)
                }
            }
        }
    }

    @ViewBuilder
    private func setAnalogView(target: ClockTime?) -> some View {
        VStack(spacing: 16) {
            if let target {
                DigitalClockDisplay(time: target, label: "Stel deze tijd in", accentColor: .orange)
            }
            AnalogClockView(time: ClockTime(hour: analogHour, minute: analogMinute), accentColor: .white)
                .frame(height: 220)
            HStack(spacing: 16) {
                stepControl(title: "Uur", value: $analogHour, range: 0...23, step: 1)
                stepControl(title: "Min", value: $analogMinute, range: 0...59, step: level.difficulty >= 3 ? 1 : 5)
            }
            Button {
                let answer = ClockTime(hour: analogHour, minute: analogMinute)
                withAnimation {
                    viewModel.submit(answer: .time(answer))
                }
            } label: {
                Text("Controleer")
                    .font(.headline)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.25), in: Capsule())
                    .foregroundStyle(.white)
            }
        }
    }

    @ViewBuilder
    private func setDigitalView(target: ClockTime?) -> some View {
        VStack(spacing: 16) {
            if let target {
                AnalogClockView(time: target, showSeconds: level.difficulty >= 3, accentColor: .white)
                    .frame(height: 200)
            }
            HStack(spacing: 24) {
                picker(title: "Uur", selection: $digitalHour, range: 0...23)
                picker(title: "Min", selection: $digitalMinute, range: 0...59, step: level.difficulty >= 3 ? 1 : 5)
            }
            Button {
                let answer = ClockTime(hour: digitalHour, minute: digitalMinute)
                withAnimation {
                    viewModel.submit(answer: .time(answer))
                }
            } label: {
                Text("Controleer")
                    .font(.headline)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.25), in: Capsule())
                    .foregroundStyle(.white)
            }
        }
    }

    @ViewBuilder
    private func timelineView(for question: ClockQuestion) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Start: \(question.targetTime?.digitalString ?? "--:--")")
                Spacer()
                Text("? Minuten")
            }
            .font(.headline)
            .foregroundStyle(.white)
            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(height: 6)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white)
                        .frame(width: 30)
                        .offset(x: 0)
                }
        }
    }

    private func feedbackView(_ feedback: TrainingSessionViewModel.Feedback) -> some View {
        HStack {
            Image(systemName: feedback.isPositive ? "hand.thumbsup.fill" : "exclamationmark.triangle.fill")
                .font(.title3)
            VStack(alignment: .leading) {
                Text(feedback.title)
                    .font(.headline)
                Text(feedback.message)
                    .font(.subheadline)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(feedback.isPositive ? Color.green.opacity(0.25) : Color.red.opacity(0.25), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .foregroundStyle(.white)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Spacer()
            VStack(spacing: 16) {
                Text("Level voltooid!")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text("Score: \(viewModel.score)")
                    .font(.title2)
                    .foregroundStyle(.white)
                Text("Goede antwoorden: \(viewModel.correctCount) / \(viewModel.questions.count)")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                Button {
                    let result = viewModel.makeResult()
                    onComplete(result)
                    dismiss()
                } label: {
                    Text("Terug naar kaart")
                        .font(.headline)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.25), in: Capsule())
                        .foregroundStyle(.white)
                }
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.7).ignoresSafeArea())
    }

    private func resetInputs() {
        selectedOptionID = nil
        let base = ClockTime(hour: 6, minute: 0)
        analogHour = base.hour
        analogMinute = base.minute
        digitalHour = base.hour
        digitalMinute = base.minute
        viewModel.feedback = nil
    }

    private func stepControl(title: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Stepper(value: value, in: range, step: step) {
                Text(String(format: "%02d", value.wrappedValue))
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .labelsHidden()
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func picker(title: String, selection: Binding<Int>, range: ClosedRange<Int>, step: Int = 1) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Picker(title, selection: selection) {
                ForEach(Array(stride(from: range.lowerBound, through: range.upperBound, by: step)), id: \.self) { value in
                    Text(String(format: "%02d", value))
                        .tag(value)
                }
            }
            .frame(height: 100)
            .clipped()
            .pickerStyle(.wheel)
            .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

#Preview {
    NavigationStack {
        TrainingSessionView(level: ClockAdventure.levels[0]) { _ in }
    }
}
