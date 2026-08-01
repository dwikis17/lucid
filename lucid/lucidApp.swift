import SwiftData
import SwiftUI
import RevenueCat

@main
struct LucidCueApp: App {
  private let modelContainer: ModelContainer
  @State private var appModel: AppModel

  init() {
    RevenueCatConfiguration.configure()
    let container = Self.makeModelContainer()
    modelContainer = container
    _appModel = State(initialValue: AppModel(modelContext: container.mainContext))
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(appModel)
        .preferredColorScheme(.dark)
    }
    .modelContainer(modelContainer)
  }

  private static func makeModelContainer() -> ModelContainer {
    let schema = Schema([
      DreamEntry.self,
      StoredRealityCheckEvent.self,
      StoredWBTBSession.self,
    ])
    let cloudConfiguration = ModelConfiguration(
      "Lucid",
      schema: schema,
      cloudKitDatabase: .private("iCloud.com.dwiki.lucid")
    )

    do {
      return try ModelContainer(for: schema, configurations: [cloudConfiguration])
    } catch {
      let localConfiguration = ModelConfiguration("Lucid", schema: schema)
      do {
        return try ModelContainer(for: schema, configurations: [localConfiguration])
      } catch {
        fatalError("Could not create the Lucid data store: \(error.localizedDescription)")
      }
    }
  }
}
