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

// MARK: - Scoring
final class TennisMatch: ObservableObject {
    @Published var gameType: GameType = .singles
    let leftTeam = Team(name: "ME")
    let rightTeam = Team(name: "💩")

    @Published private(set) var leftCurrentPoints: Int = 0
    @Published private(set) var leftWonGames: Int = 0
    
    @Published private(set) var rightCurrentPoints: Int = 0
    @Published private(set) var rightWonGames: Int = 0

    private var isNoAdActive: Bool { gameType == .doubles }

    private var history: [MatchSnapshot] = []

    
    func point(toLeft: Bool) {
        pushHistory()
        if toLeft {
            leftCurrentPoints += 1
        } else {
            rightCurrentPoints += 1
        }
        evaluateGameIfEnded()
        WKInterfaceDevice.current().play(.click)
    }

    func undo() {
        guard let last = history.popLast() else { return }
        leftCurrentPoints = last.leftPoints
        rightCurrentPoints = last.rightPoints
        leftWonGames = last.leftGames
        rightWonGames = last.rightGames
    }

    func resetMatch() {
        leftCurrentPoints = 0
        rightCurrentPoints = 0
        leftWonGames = 0
        rightWonGames = 0
        history.removeAll()
    }
    
    private func pushHistory() {
        let snapshot = MatchSnapshot(
            leftPoints: leftCurrentPoints,
            rightPoints: rightCurrentPoints,
            leftGames: leftWonGames,
            rightGames: rightWonGames
        )
        history.append(snapshot)
        if history.count > 10 {
            history.removeFirst()
        }
    }

    private func evaluateGameIfEnded() {
        // No-Ad scoring: at 40–40 (both >=3), the next point wins the game
        if isNoAdActive,
           leftCurrentPoints >= 3,
           rightCurrentPoints >= 3,
           leftCurrentPoints != rightCurrentPoints {
            if leftCurrentPoints > rightCurrentPoints {
                leftWonGames += 1
            } else {
                rightWonGames += 1
            }
            leftCurrentPoints = 0
            rightCurrentPoints = 0
            WKInterfaceDevice.current().play(.success)
            return
        }

        // Standard advantage scoring
        if leftCurrentPoints >= 4 || rightCurrentPoints >= 4 {
            if abs(leftCurrentPoints - rightCurrentPoints) >= 2 {
                if leftCurrentPoints > rightCurrentPoints {
                    leftWonGames += 1
                } else {
                    rightWonGames += 1
                }
                leftCurrentPoints = 0
                rightCurrentPoints = 0
                WKInterfaceDevice.current().play(.success)
            }
        }
    }
    
    func currentlyWinning(forLeft: Bool) -> Bool {
        // if nil, same score
        if forLeft {
            if leftWonGames > rightWonGames {
                return true
            } else if leftWonGames < rightWonGames {
                return false
            } else if leftCurrentPoints > rightCurrentPoints {
                return true
            } else {
                return false
            }
        } else {
            if leftWonGames < rightWonGames {
                return true
            } else if leftWonGames > rightWonGames {
                return false
            } else if leftCurrentPoints < rightCurrentPoints {
                return true
            } else {
                return false
            }
        }
    }

    func leftLabel() -> String {
        label(
            for: leftCurrentPoints,
            vs: rightCurrentPoints
        )
    }
    
    func rightLabel() -> String {
        label(
            for: rightCurrentPoints,
            vs: leftCurrentPoints
        )
    }

    private func label(for point: Int, vs opponent: Int) -> String {
        if point >= 3 && opponent >= 3 {
            if point == opponent { return "Deuce" }
            if point == opponent + 1 { return "AD" }
        }
        switch point {
        case 0: return "Love"
        case 1: return "15"
        case 2: return "30"
        case 3: return "40"
        default:
            // In rare transient states (e.g. tapping fast before evaluation), show numeric lead
            return "+\(point - 3)"
        }
    }
}
