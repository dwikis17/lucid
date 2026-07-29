import SwiftUI

struct WatchSettingsStatusView: View {
  @Environment(WatchAppModel.self) private var appModel

  var body: some View {
    List {
      Section("Current cue") {
        LabeledContent("Word", value: appModel.settings.cueWord)
        LabeledContent("Haptic", value: appModel.settings.selectedHaptic.displayName)
        LabeledContent(
          "Night cue",
          value: appModel.settings.isNightCueEnabled ? "Enabled" : "Disabled"
        )
      }

      Section("Connection") {
        LabeledContent(
          "iPhone",
          value: appModel.connectivity.isReachable ? "Reachable" : "Sync pending"
        )
        Text("The watch keeps the latest settings even when iPhone is unavailable.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      Section("Timing") {
        Text(
          "Focus modes and system settings control notification delivery and haptics."
        )
        .font(.footnote)
      }

      #if DEBUG
      Section("Developer") {
        Button("Night cue in 15 seconds") {
          Task {
            await appModel.scheduleDebugNightCue()
          }
        }
        Button("Clear pending notifications", role: .destructive) {
          Task {
            await appModel.clearPendingNotifications()
          }
        }
        Button("Play selected haptic", action: appModel.playSelectedHaptic)
      }

      Section("Pending") {
        if appModel.pendingIdentifiers.isEmpty {
          Text("None")
        } else {
          ForEach(appModel.pendingIdentifiers, id: \.self) { identifier in
            Text(identifier)
              .font(.footnote)
          }
        }
      }
      #endif
    }
    .navigationTitle("Status")
    #if DEBUG
    .task {
      await appModel.refreshPendingIdentifiers()
    }
    #endif
  }
}
