import SwiftUI

struct ContentView: View {
  @Environment(WatchAppModel.self) private var appModel

  var body: some View {
    @Bindable var appModel = appModel

    NavigationStack {
      WatchHomeView()
        .navigationDestination(isPresented: $appModel.isShowingRealityCheck) {
          WatchRealityCheckView(source: appModel.realityCheckSource)
        }
    }
    .task {
      await appModel.start()
    }
  }
}
