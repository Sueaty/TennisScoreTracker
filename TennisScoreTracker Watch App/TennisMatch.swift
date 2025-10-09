//
//  TennisMatch.swift
//  TennisScoreTracker
//
//  Created by 조수정 on 10/6/25.
//

import Combine
import WatchKit

// MARK: - Models
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


final class TennisSettings: ObservableObject {
    @Published var useAdvantage: Bool = false
    // Tie-break set :
    //  - immediate action at 6 All set game
    //  - set won at 7pt + 2 margins
    @Published var useTiebreakAtSixAll: Bool = false
}

final class TennisMatch: ObservableObject {
    let leftTeam = Team(name: "ME")
    let rightTeam = Team(name: "💩")
    
    @Published private(set) var setFinished: Bool = false
    @Published private(set) var winner: Team?
    
    @Published private(set) var advantageEnabled: Bool = false
    @Published private(set) var tiebreakEnabled: Bool = false
    @Published private(set) var inTiebreak: Bool = false

    @Published private(set) var leftCurrentPoints: Int = 0
    @Published private(set) var leftWonGames: Int = 0
    
    @Published private(set) var rightCurrentPoints: Int = 0
    @Published private(set) var rightWonGames: Int = 0

    private var history: [MatchSnapshot] = []

    func configureRules(useAdvantage: Bool, useTiebreak: Bool) {
        self.advantageEnabled = useAdvantage
        self.tiebreakEnabled = useTiebreak
    }
    
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
        inTiebreak = (tiebreakEnabled && leftWonGames == 6 && rightWonGames == 6)
        setFinished = false
        winner = nil
        evaluateSetIfEnded()
    }

    func resetMatch() {
        leftCurrentPoints = 0
        rightCurrentPoints = 0
        leftWonGames = 0
        rightWonGames = 0
        inTiebreak = false
        setFinished = false
        winner = nil
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
        // Enter TB at 6-all
        if tiebreakEnabled, !inTiebreak, leftWonGames == 6, rightWonGames == 6 {
            inTiebreak = true
        }
        // If TB, win 7pt + w/ margin 2
        if inTiebreak {
            if (leftCurrentPoints >= 7 || rightCurrentPoints >= 7),
               abs(leftCurrentPoints - rightCurrentPoints) >= 2 {
                // decide winner directly from TB points
                let leftWonTB = leftCurrentPoints > rightCurrentPoints
                if leftWonTB {
                    leftWonGames += 1  // results in 7–6
                } else {
                    rightWonGames += 1
                }
                leftCurrentPoints = 0
                rightCurrentPoints = 0
                inTiebreak = false
                winner = leftWonTB ? leftTeam : rightTeam
                setFinished = true
                WKInterfaceDevice.current().play(.success)
            }
            return
        }
        // No-AD scoring
        //  - Next point wins the game after 40-40
        if !advantageEnabled,
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
            evaluateSetIfEnded()
            WKInterfaceDevice.current().play(.success)
            return
        }
        // Standard AD scoring
        if leftCurrentPoints >= 4 || rightCurrentPoints >= 4 {
            if abs(leftCurrentPoints - rightCurrentPoints) >= 2 {
                if leftCurrentPoints > rightCurrentPoints {
                    leftWonGames += 1
                } else {
                    rightWonGames += 1
                }
                leftCurrentPoints = 0
                rightCurrentPoints = 0
                evaluateSetIfEnded()
                WKInterfaceDevice.current().play(.success)
            }
        }
    }
    
    private func evaluateSetIfEnded() {
        let maxGames = max(leftWonGames, rightWonGames)
        let diff = abs(leftWonGames - rightWonGames)
        
        if tiebreakEnabled {
            /// Note: 7–6 (or 6–7) via tie-break is handled in evaluateGameIfEnded(), where `winner` and `setFinished` are set.
            if (maxGames == 6 && diff >= 2) || (maxGames == 7 && diff >= 2) {
                setFinished = true
                winner = (leftWonGames > rightWonGames) ? leftTeam : rightTeam
            }
        } else {
            if maxGames >= 6 && diff >= 2 {
                setFinished = true
                winner = (leftWonGames > rightWonGames) ? leftTeam : rightTeam
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
    
    func isCurrentWinner(forLeft: Bool) -> Bool {
        guard let winner else { return false }
        return switch forLeft {
        case true:
            winner.name == leftTeam.name
        case false:
            winner.name == rightTeam.name
        }
    }

    func leftLabel() -> LocalizedStringResource {
        label(
            for: leftCurrentPoints,
            vs: rightCurrentPoints
        )
    }
    
    func rightLabel() -> LocalizedStringResource {
        label(
            for: rightCurrentPoints,
            vs: leftCurrentPoints
        )
    }

    private func label(for point: Int, vs opponent: Int) -> LocalizedStringResource {
        // Display numeric points during tie-break
        if inTiebreak {
            return LocalizedStringResource(stringLiteral: String(point))
        }
        if point >= 3 && opponent >= 3 {
            if point == opponent {
                return LocalizedStringResource(stringLiteral: "Deuce")
            }
            if point == opponent + 1 { return "AD" }
        }
        switch point {
        case 0: return "Love"
        case 1: return "15"
        case 2: return "30"
        case 3: return "40"
        default:
            return "-"
        }
    }
}
