import SwiftUI

struct ContentView: View {
  @Environment(AppModel.self) private var appModel
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

  var body: some View {
    Group {
      if hasCompletedOnboarding {
        MainTabView()
      } else {
        OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
      }
    }
    .task {
      await appModel.didLaunch()
    }
  }
}
