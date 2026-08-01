import SwiftData
import SwiftUI

struct ContentView: View {
  @Environment(AppModel.self) private var appModel
  @Environment(\.scenePhase) private var scenePhase
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

  var body: some View {
    Group {
      if hasCompletedOnboarding && appModel.appLock.isLocked {
        AppLockView()
      } else if hasCompletedOnboarding {
        MainTabView()
      } else {
        OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
      }
    }
    .task {
      await appModel.didLaunch()
    }
    .onChange(of: scenePhase) { _, newValue in
      switch newValue {
      case .background:
        appModel.appLock.lockIfNeeded()
      case .active:
        Task {
          await appModel.didBecomeActive()
          if appModel.appLock.isLocked {
            _ = await appModel.appLock.unlock()
          }
        }
      default:
        break
      }
    }
  }
}

#Preview {
  let container = try! ModelContainer(
    for: StoredRealityCheckEvent.self, DreamEntry.self, StoredWBTBSession.self,
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
  )
  let appModel = AppModel(modelContext: container.mainContext)

  return ContentView()
    .environment(appModel)
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
