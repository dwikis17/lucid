import SwiftUI

@main
struct LucidCueWatchApp: App {
  @Environment(\.scenePhase) private var scenePhase
  @State private var appModel = WatchAppModel()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(appModel)
        .preferredColorScheme(.dark)
    }
    .onChange(of: scenePhase) { _, newValue in
      guard newValue == .active else { return }
      Task {
        await appModel.didBecomeActive()
      }
    }
  }
}
