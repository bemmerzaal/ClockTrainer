import SwiftUI

struct DigitalClockDisplay: View {
    var time: ClockTime
    var label: String? = nil
    var accentColor: Color = .blue

    var body: some View {
        VStack(spacing: 8) {
            if let label {
                Text(label)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            Text(time.digitalString)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(colors: [accentColor.opacity(0.9), accentColor.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                )
                .shadow(color: accentColor.opacity(0.4), radius: 12, x: 0, y: 10)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Digitale tijd: \(time.digitalString)")
    }
}

#Preview {
    ZStack {
        Color.black
        DigitalClockDisplay(time: ClockTime(hour: 7, minute: 45), label: "Oefening", accentColor: .purple)
    }
    .ignoresSafeArea()
}
