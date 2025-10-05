//
//  SetupGameView.swift
//  TennisScoreTracker
//
//  Created by 조수정 on 10/6/25.
//

import SwiftUI

struct SetupGameView: View {
    @ObservedObject var match: TennisMatch
    var onStart: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 10) {
            ChoiceButton(
                title: "Singles",
                isSelected: match.gameType == .singles
            ) {
                match.gameType = .singles
            }
            ChoiceButton(
                title: "Doubles",
                isSelected: match.gameType == .doubles
            ) {
                match.gameType = .doubles
            }
            
            Divider()
            
            Button {
                onStart?()
            } label: {
                Text("Start Match")
            }
        }
    }
}
