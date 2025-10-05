import SwiftUI

// MARK: - Views
struct ContentView: View {
    @StateObject private var match = TennisMatch()
    @State private var isSetupShown = true
    
    var body: some View {
        Group {
            if isSetupShown {
                SetupGameView(match: match) {
                    isSetupShown = false
                }
            } else {
                ScoreView(match: match) {
                    match.resetMatch()
                    isSetupShown = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
