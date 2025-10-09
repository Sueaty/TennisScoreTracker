//
//  SetupGameView.swift
//  TennisScoreTracker
//
//  Created by 조수정 on 10/6/25.
//

import SwiftUI

struct SetupGameView: View {
    @EnvironmentObject var settings: TennisSettings
    @ObservedObject var match: TennisMatch
    var onStart: (() -> Void)?
    
    var body: some View {
        VStack {
            Text("Set-Scoring Options")
                .font(.footnote)
            
            ChoiceButton(
                title: "Advantage",
                isSelected: settings.useAdvantage == true
            ) {
                settings.useAdvantage.toggle()
            }
            ChoiceButton(
                title: "Tiebreak",
                isSelected: settings.useTiebreakAtSixAll == true
            ) {
                settings.useTiebreakAtSixAll.toggle()
            }
            
            Spacer(minLength: 8)
            Divider()
            Spacer(minLength: 8)
            
            Button {
                onStart?()
            } label: {
                Text("Start")
            }
            .background(
                Capsule(style: .continuous)
                    .fill(Color(hex: "ABC270"))
            )
        }
    }
}

struct ChoiceButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            let localizedText = LocalizedStringResource(stringLiteral: title)
            Text(String(localized: localizedText))
        }
        .background(
            Capsule(style: .continuous)
                .fill(isSelected ? Color(hex: "472a0e") : Color(hex: "ABC270"))
        )
    }
}

#Preview {
    let match = TennisMatch()
    SetupGameView(match: match)
//        .environment(\.locale, .init(identifier: "ko"))
        .environmentObject(TennisSettings())
}
