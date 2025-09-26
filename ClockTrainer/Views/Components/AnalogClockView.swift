import SwiftUI

struct AnalogClockView: View {
    let time: ClockTime
    var showSeconds: Bool = false
    var accentColor: Color = .orange

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.white, accentColor.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle()
                    .strokeBorder(LinearGradient(colors: [accentColor.opacity(0.8), .white.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: size * 0.04)

                ForEach(0..<60) { tick in
                    Capsule()
                        .fill(tick % 5 == 0 ? accentColor : accentColor.opacity(0.4))
                        .frame(width: tick % 5 == 0 ? size * 0.015 : size * 0.008, height: tick % 15 == 0 ? size * 0.07 : size * 0.04)
                        .offset(y: -size / 2 + (tick % 5 == 0 ? size * 0.09 : size * 0.1))
                        .rotationEffect(.degrees(Double(tick) * 6))
                }

                HourHand()
                    .stroke(accentColor, style: StrokeStyle(lineWidth: size * 0.05, lineCap: .round))
                    .rotationEffect(time.hourAngle)
                    .frame(width: size * 0.45, height: size * 0.45)

                MinuteHand()
                    .stroke(accentColor, style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round))
                    .rotationEffect(time.minuteAngle)
                    .frame(width: size * 0.6, height: size * 0.6)

                if showSeconds {
                    SecondHand()
                        .stroke(Color.red.opacity(0.7), style: StrokeStyle(lineWidth: size * 0.015, lineCap: .round))
                        .rotationEffect(time.secondAngle)
                        .frame(width: size * 0.65, height: size * 0.65)
                }

                Circle()
                    .fill(accentColor)
                    .frame(width: size * 0.08)
                    .shadow(color: accentColor.opacity(0.4), radius: size * 0.05, x: 0, y: 0)
            }
            .frame(width: size, height: size)
            .accessibilityLabel("Analoge klok: \(time.digitalString)")
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private struct HourHand: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.35))
            return path
        }
    }

    private struct MinuteHand: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.08))
            return path
        }
    }

    private struct SecondHand: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.1))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            return path
        }
    }
}

#Preview {
    AnalogClockView(time: ClockTime(hour: 10, minute: 15, second: 30), showSeconds: true)
        .padding()
        .frame(width: 220, height: 220)
        .background(Color.gray.opacity(0.2))
}
