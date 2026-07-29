import SwiftData
import SwiftUI

@main
struct LucidCueApp: App {
  private let modelContainer: ModelContainer
  @State private var appModel: AppModel

  init() {
    do {
      let container = try ModelContainer(for: StoredRealityCheckEvent.self)
      modelContainer = container
      _appModel = State(initialValue: AppModel(modelContext: container.mainContext))
    } catch {
      fatalError("Could not create the local history store: \(error.localizedDescription)")
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(appModel)
    }
    .modelContainer(modelContainer)
  }
}
