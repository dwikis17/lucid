import SwiftUI

struct SettingsView: View {
  @Environment(AppModel.self) private var appModel

  var body: some View {
    List {
      Section {
        NavigationLink("Cue schedule", value: SettingsDestination.setup)
      }

      Section("Notifications") {
        LabeledContent("Permission", value: authorizationDescription)
        if appModel.authorizationStatus == .denied {
          Button(
            "Open System Settings",
            systemImage: "gear",
            action: appModel.openSystemNotificationSettings
          )
        } else if appModel.authorizationStatus == .notDetermined {
          Button(
            "Allow Notifications",
            systemImage: "bell.badge",
            action: didTapPermissionButton
          )
        }
      }

      Section("Apple Watch") {
        LabeledContent(
          "Paired",
          value: appModel.connectivity.isWatchPaired ? "Yes" : "No"
        )
        LabeledContent(
          "Watch app",
          value: appModel.connectivity.isWatchAppInstalled ? "Installed" : "Unavailable"
        )
        Text("Settings synchronize eventually; the watch does not need to be reachable now.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      Section("Privacy") {
        Text(
          "Your cue settings and reality-check history are stored locally. The MVP does " +
            "not send your data to a server."
        )
        Text(
          "Lucid Cue is a habit-training and wellness application. Results vary, and the " +
            "app is not a medical or sleep-treatment product."
        )
        .foregroundStyle(.secondary)
      }

      #if DEBUG
      Section("Developer") {
        NavigationLink("Test controls", value: SettingsDestination.debug)
      }
      #endif
    }
    .navigationTitle("Settings")
    .navigationDestination(for: SettingsDestination.self) { destination in
      switch destination {
      case .setup:
        SetupView()
          .navigationTitle("Cue Schedule")
      case .debug:
        #if DEBUG
        DebugView()
        #else
        EmptyView()
        #endif
      }
    }
  }

  private var authorizationDescription: String {
    switch appModel.authorizationStatus {
    case .notDetermined:
      "Not requested"
    case .denied:
      "Denied"
    case .authorized:
      "Allowed"
    case .provisional:
      "Provisional"
    case .ephemeral:
      "Temporary"
    @unknown default:
      "Unknown"
    }
  }

  private func didTapPermissionButton() {
    Task {
      await appModel.requestNotificationPermission()
    }
  }
}
