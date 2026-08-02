import SwiftData
import SwiftUI

struct MainTabView: View {
  @Environment(AppModel.self) private var appModel
  @State private var selectedTab = MainTab.home

  var body: some View {
    @Bindable var appModel = appModel

    TabView(selection: $selectedTab) {
      NavigationStack {
        HomeView()
      }
      .tabItem {
        Label("Home", systemImage: "moon.stars")
      }
      .tag(MainTab.home)

      NavigationStack {
        JournalView()
      }
      .tabItem {
        Label("Journal", systemImage: "book.closed")
      }
      .tag(MainTab.journal)

      NavigationStack {
        ProgressDashboardView()
      }
      .tabItem {
        Label("Progress", systemImage: "chart.bar.xaxis")
      }
      .tag(MainTab.progress)

      NavigationStack {
        SettingsView()
      }
      .tabItem {
        Label("Settings", systemImage: "gearshape")
      }
      .tag(MainTab.settings)
    }
    .toolbarBackground(LucidTheme.deepTwilight, for: .tabBar)
    .toolbarBackground(.visible, for: .tabBar)
    .sheet(item: Binding(
      get: {
        guard let route = appModel.route else { return nil }
        if case .dreamEntry = route { return nil }
        return route
      },
      set: { appModel.route = $0 }
    )) { route in
      switch route {
      case let .realityCheck(source):
        RealityCheckView(source: source)
      case .dreamEntry:
        EmptyView()
      case .wbtb:
        WBTBView()
      }
    }
    .fullScreenCover(item: Binding(
      get: {
        guard let route = appModel.route else { return nil }
        if case .dreamEntry = route { return route }
        return nil
      },
      set: { appModel.route = $0 }
    )) { route in
      if case let .dreamEntry(id) = route {
        if let dream = appModel.dreamEntry(id: id) {
          NavigationStack {
            DreamEditorView(dream: dream)
          }
        } else {
          ContentUnavailableView("Dream unavailable", systemImage: "moon.zzz")
        }
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

  return MainTabView()
    .environment(appModel)
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
