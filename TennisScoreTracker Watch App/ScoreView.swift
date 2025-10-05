//
//  ScoreView.swift
//  TennisScoreTracker
//
//  Created by 조수정 on 10/6/25.
//

import SwiftUI

struct ScoreView: View {
    @ObservedObject var match: TennisMatch
    var onGameRestart: () -> Void
    
    var body: some View {
        VStack {
            // 게임 점수
            HStack {
                PointCard(
                    teamName: match.leftTeam.name,
                    gamesWonCount: match.leftWonGames,
                    currentScore: match.leftLabel(),
                    isWinning: match.currentlyWinning(forLeft: true)
                ) {
                    match.point(toLeft: true)
                }
                Spacer()
                PointCard(
                    teamName: match.rightTeam.name,
                    gamesWonCount: match.rightWonGames,
                    currentScore: match.rightLabel(),
                    isWinning: match.currentlyWinning(forLeft: false)
                ) {
                    match.point(toLeft: false)
                }
            }
            
            // 컨트롤
            HStack {
                Button(action: match.undo) {
                    VStack(alignment: .center) {
                        Image(systemName: "arrow.uturn.backward")
                        Text("undo")
                            .font(.footnote)
                            .fontWeight(.light)
                    }
                }
                
                Button(action: onGameRestart) {
                    VStack(alignment: .center) {
                        Image(systemName: "arrow.clockwise")
                        Text("restart")
                            .font(.footnote)
                            .fontWeight(.light)
                    }
                }
            }
            .font(.caption2)
        }
    }
}

struct PointCard: View {
    let teamName: String
    let gamesWonCount: Int
    let currentScore: LocalizedStringResource
    let isWinning: Bool
    let addPointAction: () -> Void
    
    var body: some View {
        Button(action: addPointAction) {
            VStack(alignment: .center) {
                Text(teamName)
                Text("\(gamesWonCount)")
                    .font(.title).bold()
                Text(String(localized: currentScore))
                    .font(.headline)
                Text("Tap")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ThickCardButtonStyle(isWinning: isWinning))
    }
}

struct ThickCardButtonStyle: ButtonStyle {
    var isWinning: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isWinning
                        ? Color(hex: "FDA769").opacity(configuration.isPressed ? 0.7 : 0.9)
                        : Color(hex: "ABC270").opacity(configuration.isPressed ? 0.7 : 1.0)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.gray.opacity(0.2))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

#Preview {
    let match = TennisMatch()
    ScoreView(match: match) {
        print("back")
    }
    .environment(\.locale, .init(identifier: "ko"))
}
