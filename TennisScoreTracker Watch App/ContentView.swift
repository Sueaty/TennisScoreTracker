import SwiftUI

// MARK: - Views
struct ContentView: View {
    @StateObject private var match = TennisMatch()
    @State private var isSetupShown = true

    var body: some View {
        Group {
            if isSetupShown {
                SetupView(match: match) { isSetupShown = false }
            } else {
                ScoreView(match: match) { isSetupShown = true }
            }
        }
    }
}

struct SetupView: View {
    @ObservedObject var match: TennisMatch
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("Tennis Tracker")
                .font(.headline)
            HStack(spacing: 8) {
            ChoiceButton(title: "Singles", isSelected: match.gameType == .singles) {
                match.gameType = .singles
            }
            ChoiceButton(title: "Doubles", isSelected: match.gameType == .doubles) {
                match.gameType = .doubles
            }
        }

            if match.gameType == .singles {
                Toggle("No-Ad Scoring", isOn: $match.noAdScoring)
                    .font(.caption)
            } else {
                Text("Doubles uses No‑Ad at deuce (one deciding point)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if match.gameType == .singles {
                TextField("Your name", text: $match.leftTeam.name)
                TextField("Opponent name", text: $match.rightTeam.name)
            } else {
                TextField("Team A name", text: $match.leftTeam.name)
                TextField("Team B name", text: $match.rightTeam.name)
            }

            Button(action: onStart) {
                Text("Start Match")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct ScoreView: View {
    @ObservedObject var match: TennisMatch
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Button(action: onBack) { Image(systemName: "chevron.left") }
                Spacer()
                Text(match.gameType.rawValue)
                    .font(.caption2).foregroundStyle(.secondary)
            }

            // Games row
            HStack {
                TeamLabel(name: match.leftTeam.name)
                Spacer(minLength: 6)
                Text("Games")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 6)
                TeamLabel(name: match.rightTeam.name, alignTrailing: true)
            }
            .padding(.top, 2)

            HStack {
                ScorePill(value: match.leftGames)
                Spacer()
                ScorePill(value: match.rightGames)
            }

            // Current game (points)
            HStack {
                PointCard(title: match.leftLabel(), action: { match.point(toLeft: true) })
                PointCard(title: match.rightLabel(), action: { match.point(toLeft: false) })
            }
            .padding(.top, 4)

            // Controls
            HStack(spacing: 8) {
                Button("Undo") { match.undo() }
                    .buttonStyle(.bordered)
                Button("Reset Game") { match.resetCurrentGame() }
                    .buttonStyle(.bordered)
                Button("Reset Match") { match.resetMatch() }
                    .buttonStyle(.bordered)
            }
            .font(.caption2)
        }
        .padding()
    }
}

// MARK: - Subviews
struct ChoiceButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout)
                .fontWeight(isSelected ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(SelectableCapsuleStyle(isSelected: isSelected))
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

struct SelectableCapsuleStyle: ButtonStyle {
    var isSelected: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(configuration.isPressed ? 0.6 : 0.3)
                                      : Color.gray.opacity(configuration.isPressed ? 0.25 : 0.15))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.6) : Color.gray.opacity(0.25), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

// MARK: - Subviews
struct TeamLabel: View {
    let name: String
    var alignTrailing: Bool = false

    var body: some View {
        Text(name)
            .font(.caption2)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: alignTrailing ? .trailing : .leading)
            .minimumScaleFactor(0.8)
            .accessibilityLabel(Text("Team: \(name)"))
    }
}

struct ScorePill: View {
    let value: Int
    var body: some View {
        Text("\(value)")
            .font(.title2).bold()
            .frame(width: 52, height: 32)
            .background(Capsule().fill(Color.gray.opacity(0.2)))
            .accessibilityLabel(Text("Games: \(value)"))
    }
}

struct PointCard: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.5)
                Text("Tap to add point")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
        }
        .buttonStyle(ThickCardButtonStyle())
        .accessibilityAddTraits(.isButton)
    }
}

struct ThickCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(configuration.isPressed ? Color.accentColor.opacity(0.25) : Color.gray.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.gray.opacity(0.2))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview("Watch") {
    ContentView()
}
