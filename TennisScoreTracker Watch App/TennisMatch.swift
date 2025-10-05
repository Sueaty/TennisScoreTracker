//
//  TennisMatch.swift
//  TennisScoreTracker
//
//  Created by 조수정 on 10/6/25.
//

import Combine
import WatchKit

// MARK: - Models
enum GameType: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case singles = "Singles"
    case doubles = "Doubles"
}

struct Team: Identifiable, Hashable {
    let id = UUID()
    var name: String
}

struct MatchSnapshot: Equatable {
    var leftPoints: Int
    var rightPoints: Int
    var leftGames: Int
    var rightGames: Int
}

// MARK: - Scoring Engine
final class TennisMatch: ObservableObject {
    @Published var gameType: GameType = .singles
    @Published var noAdScoring: Bool = false
    @Published var leftTeam = Team(name: "You / Team A")
    @Published var rightTeam = Team(name: "Opponent / Team B")

    @Published private(set) var leftPoints: Int = 0
    @Published private(set) var rightPoints: Int = 0

    @Published private(set) var leftGames: Int = 0
    @Published private(set) var rightGames: Int = 0

    private var isNoAdActive: Bool { noAdScoring || gameType == .doubles }

    private var history: [MatchSnapshot] = []

    // Give a point to a side and apply tennis rules (deuce/advantage/game)
    func point(toLeft: Bool) {
        pushHistory()
        if toLeft { leftPoints += 1 } else { rightPoints += 1 }
        evaluateGameIfEnded()
        WKInterfaceDevice.current().play(.click)
    }

    func undo() {
        guard let last = history.popLast() else { return }
        leftPoints = last.leftPoints
        rightPoints = last.rightPoints
        leftGames = last.leftGames
        rightGames = last.rightGames
        WKInterfaceDevice.current().play(.directionDown)
    }

    func resetCurrentGame() {
        pushHistory()
        leftPoints = 0
        rightPoints = 0
        WKInterfaceDevice.current().play(.retry)
    }

    func resetMatch() {
        pushHistory()
        leftPoints = 0
        rightPoints = 0
        leftGames = 0
        rightGames = 0
        WKInterfaceDevice.current().play(.failure)
    }

    // MARK: - Helpers
    private func pushHistory() {
        history.append(MatchSnapshot(leftPoints: leftPoints,
                                     rightPoints: rightPoints,
                                     leftGames: leftGames,
                                     rightGames: rightGames))
        if history.count > 50 { history.removeFirst() }
    }

    private func evaluateGameIfEnded() {
        // No-Ad scoring: at 40–40 (both >=3), the next point wins the game
        if isNoAdActive, leftPoints >= 3, rightPoints >= 3, leftPoints != rightPoints {
            if leftPoints > rightPoints { leftGames += 1 } else { rightGames += 1 }
            leftPoints = 0; rightPoints = 0
            WKInterfaceDevice.current().play(.success)
            return
        }

        // Standard advantage scoring
        if leftPoints >= 4 || rightPoints >= 4 {
            if abs(leftPoints - rightPoints) >= 2 {
                if leftPoints > rightPoints { leftGames += 1 } else { rightGames += 1 }
                leftPoints = 0; rightPoints = 0
                WKInterfaceDevice.current().play(.success)
            }
        }
    }

    func leftLabel() -> String { label(for: leftPoints, vs: rightPoints, isLeft: true) }
    func rightLabel() -> String { label(for: rightPoints, vs: leftPoints, isLeft: false) }

    private func label(for p: Int, vs o: Int, isLeft: Bool) -> String {
        if p >= 3 && o >= 3 {
            if p == o { return "Deuce" }
            if p == o + 1 { return "Advantage" }
        }
        switch p {
        case 0: return "Love"
        case 1: return "15"
        case 2: return "30"
        case 3: return "40"
        default:
            // In rare transient states (e.g. tapping fast before evaluation), show numeric lead
            return "+\(p - 3)"
        }
    }
}
