import SwiftData
import RevenueCatUI
import SwiftUI

struct SettingsView: View {
  @Environment(AppModel.self) private var appModel
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \DreamEntry.dreamDate, order: .reverse)
  private var dreams: [DreamEntry]
  @State private var isAppLockEnabled = false
  @State private var isDeleteAllPresented = false
  @State private var isCustomerCenterPresented = false

  var body: some View {
    List {
      Section {
        NavigationLink("Cue schedule", value: SettingsDestination.setup)
        if !appModel.purchaseManager.isPro {
          NavigationLink("Unlock Lucid Cue Pro", value: SettingsDestination.pro)
        }
      }

      if appModel.authorizationStatus == .denied {
        Section("Notifications") {
          Button(
            "Open System Settings",
            systemImage: "gear",
            action: appModel.openSystemNotificationSettings
          )
        }
      } else if appModel.authorizationStatus == .notDetermined {
        Section("Notifications") {
          Button(
            "Allow Notifications",
            systemImage: "bell.badge",
            action: didTapPermissionButton
          )
        }
      }

      Section("Developer Mode") {
        Button("Test WBTB alarm", systemImage: "alarm") {
          didTapTestWBTBAlarm()
        }
        Text("Schedules a real alarm in about 10 seconds so you can test the full flow.")
          .font(.footnote)
          .foregroundStyle(.secondary)
        Text(appModel.testWBTBAlarmStatus ?? "Ready")
          .font(.footnote)
          .foregroundStyle(.secondary)
        if appModel.isTestWBTBAlarmScheduled {
          Button("Cancel test alarm", systemImage: "xmark.circle", role: .destructive) {
            appModel.cancelTestWBTBAlarm()
          }
        }
      }

      Section("Privacy") {
        Toggle(
          "Protect app with Face ID",
          isOn: $isAppLockEnabled
        )
        Text(
          "Your journal and progress sync through your private iCloud account when available. " +
            "Cue settings stay on this device, and Lucid Cue does not send your data to a server."
        )
        Text(
          "Lucid Cue is a habit-training and wellness application. Results vary, and the " +
            "app is not a medical or sleep-treatment product."
        )
        .foregroundStyle(.secondary)
        Button("Delete all journal and progress data", role: .destructive) {
          isDeleteAllPresented = true
        }
      }

      if appModel.purchaseManager.isPro {
        Section("Subscription") {
          Button("Manage Lucid Cue Pro", systemImage: "person.crop.circle") {
            isCustomerCenterPresented = true
          }
        }

        Section("Your data") {
          ShareLink(
            item: DreamJournalExporter.markdown(for: dreams),
            subject: Text("Lucid Cue dream journal"),
            message: Text("Exported from Lucid Cue")
          ) {
            Label("Export journal as Markdown", systemImage: "square.and.arrow.up")
          }
        }
      }

    }
    .scrollContentBackground(.hidden)
    .lucidScreenBackground()
    .navigationTitle("Settings")
    .sheet(isPresented: $isCustomerCenterPresented) {
      CustomerCenterView()
    }
    .onAppear { isAppLockEnabled = appModel.appLock.isEnabled }
    .onChange(of: isAppLockEnabled) { _, newValue in
      appModel.setAppLockEnabled(newValue)
    }
    .confirmationDialog(
      "Delete all journal and progress data?",
      isPresented: $isDeleteAllPresented,
      titleVisibility: .visible
    ) {
      Button("Delete Everything", role: .destructive, action: deleteAllData)
    } message: {
      Text("This cannot be undone.")
    }
    .navigationDestination(for: SettingsDestination.self) { destination in
      switch destination {
      case .setup:
        SetupView()
          .navigationTitle("Cue Schedule")
      case .pro:
        ProUpgradeView()
      }
    }
  }

  private func didTapPermissionButton() {
    Task {
      await appModel.requestNotificationPermission()
    }
  }

  private func didTapTestWBTBAlarm() {
    Task {
      await appModel.scheduleTestWBTBAlarm()
    }
  }

  private func deleteAllData() {
    for dream in dreams {
      modelContext.delete(dream)
    }
    let checks = (try? modelContext.fetch(FetchDescriptor<StoredRealityCheckEvent>())) ?? []
    for check in checks {
      modelContext.delete(check)
    }
    let sessions = (try? modelContext.fetch(FetchDescriptor<StoredWBTBSession>())) ?? []
    for session in sessions {
      modelContext.delete(session)
    }
    try? modelContext.save()
  }
}
