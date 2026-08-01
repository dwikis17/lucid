import SwiftData
import SwiftUI
import RevenueCat

@main
struct LucidCueApp: App {
  private static let cloudContainerIdentifier = "iCloud.com.dwiki.lucid"

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
      cloudKitDatabase: .private(Self.cloudContainerIdentifier)
    )

    #if DEBUG
    if ProcessInfo.processInfo.arguments.contains("-InitializeCloudKitSchema") {
      do {
        try CloudKitSchemaInitializer.initialize(
          configuration: cloudConfiguration,
          containerIdentifier: Self.cloudContainerIdentifier,
          modelTypes: [
            DreamEntry.self,
            StoredRealityCheckEvent.self,
            StoredWBTBSession.self,
          ]
        )
      } catch {
        fatalError("CloudKit schema initialization failed: \(error)")
      }
    }
    #endif

    do {
      return try ModelContainer(for: schema, configurations: [cloudConfiguration])
    } catch {
      let cloudErrorDescription = error.localizedDescription
      // CloudKit entitlements can make an unspecified configuration automatic.
      // Explicitly disable CloudKit so the existing local store remains usable
      // when the private container is unavailable or not yet deployed.
      let localConfiguration = ModelConfiguration(
        "Lucid",
        schema: schema,
        cloudKitDatabase: .none
      )
      do {
        return try ModelContainer(for: schema, configurations: [localConfiguration])
      } catch {
        fatalError(
          "Could not create the Lucid data store. " +
            "CloudKit: \(cloudErrorDescription). " +
            "Local: \(error.localizedDescription)"
        )
      }
    }
  }
}
