#if DEBUG
import SwiftUI
import WatchConnectivity

struct DebugView: View {
  @Environment(AppModel.self) private var appModel

  var body: some View {
    List {
      Section("Notifications") {
        Button(
          "Schedule daytime cue in 10 seconds",
          action: didTapScheduleButton
        )
        Button("Clear all pending notifications", role: .destructive) {
          Task {
            await appModel.clearPendingNotifications()
          }
        }
        Button("Refresh pending identifiers", action: didTapRefreshButton)
      }

      Section("Pending identifiers") {
        if appModel.pendingIdentifiers.isEmpty {
          Text("None")
            .foregroundStyle(.secondary)
        } else {
          ForEach(appModel.pendingIdentifiers, id: \.self) { identifier in
            Text(identifier)
              .font(.footnote.monospaced())
              .textSelection(.enabled)
          }
        }
      }

      Section("WatchConnectivity") {
        LabeledContent(
          "Activation",
          value: String(describing: appModel.connectivity.activationState.rawValue)
        )
        LabeledContent(
          "Reachable",
          value: appModel.connectivity.isReachable ? "Yes" : "No"
        )
        Button("Send settings to watch", action: didTapSendSettingsButton)
        Button("Play selected watch haptic", action: appModel.testWatchCue)
      }
    }
    .navigationTitle("Developer")
    .task {
      await appModel.refreshPendingIdentifiers()
    }
  }

  private func didTapScheduleButton() {
    Task {
      await appModel.scheduleDebugDaytimeCue()
    }
  }

  private func didTapRefreshButton() {
    Task {
      await appModel.refreshPendingIdentifiers()
    }
  }

  private func didTapSendSettingsButton() {
    Task {
      _ = await appModel.save(settings: appModel.settings)
    }
  }
}
#endif
