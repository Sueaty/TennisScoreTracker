import SwiftUI

// MARK: - Views
struct ContentView: View {
    @StateObject private var settings = TennisSettings()
    @StateObject private var match = TennisMatch()
    @State private var isSetupShown = true
    
    var body: some View {
        Group {
            if isSetupShown {
                SetupGameView(match: match) {
                    match.configureRules(
                        useAdvantage: settings.useAdvantage,
                        useTiebreak: settings.useTiebreakAtSixAll
                    )
                    isSetupShown = false
                }
            } else {
                ScoreView(match: match) {
                    match.resetMatch()
                    isSetupShown = true
                }
            }
        }
        .environmentObject(settings)
    }
}

#Preview {
    ContentView()
        .environmentObject(TennisSettings())
}
