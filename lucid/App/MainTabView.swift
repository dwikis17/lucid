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
        HistoryView()
      }
      .tabItem {
        Label("History", systemImage: "clock.arrow.circlepath")
      }
      .tag(MainTab.history)

      NavigationStack {
        SettingsView()
      }
      .tabItem {
        Label("Settings", systemImage: "gearshape")
      }
      .tag(MainTab.settings)
    }
    .sheet(item: $appModel.route) { route in
      switch route {
      case let .realityCheck(source):
        RealityCheckView(source: source)
      }
    }
  }
}
