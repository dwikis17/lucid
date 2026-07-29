import Foundation
import Observation
import SwiftData
import UIKit
import UserNotifications

@MainActor
@Observable
final class AppModel {
  private(set) var settings: CueSettings
  private(set) var authorizationStatus = UNAuthorizationStatus.notDetermined
  private(set) var nextDaytimeReminder: Date?
  private(set) var nextNightCue: Date?
  private(set) var statusMessage: String?
  private(set) var pendingIdentifiers: [String] = []
  var route: AppRoute?

  let connectivity: IOSConnectivityService

  private let settingsRepository: SettingsRepository
  private let scheduler: any DaytimeNotificationScheduling
  private let authorizationService: any NotificationAuthorizing
  private let modelContext: ModelContext
  private let notificationDelegate: NotificationDelegate

  init(
    modelContext: ModelContext,
    settingsRepository: SettingsRepository = SettingsRepository(),
    scheduler: any DaytimeNotificationScheduling = DaytimeNotificationScheduler(),
    authorizationService: any NotificationAuthorizing = NotificationAuthorizationService(),
    connectivity: IOSConnectivityService = IOSConnectivityService()
  ) {
    self.modelContext = modelContext
    self.settingsRepository = settingsRepository
    self.scheduler = scheduler
    self.authorizationService = authorizationService
    self.connectivity = connectivity
    settings = settingsRepository.settings
    notificationDelegate = NotificationDelegate()

    configureNotificationDelegate()
    configureConnectivity()
    scheduler.registerCategory()
    UNUserNotificationCenter.current().delegate = notificationDelegate
    connectivity.activate()
  }

  func didLaunch() async {
    authorizationStatus = await authorizationService.authorizationStatus()
    await refreshScheduleState()
    sendLatestSettings()
  }

  func requestNotificationPermission() async {
    do {
      _ = try await authorizationService.requestAuthorization()
      authorizationStatus = await authorizationService.authorizationStatus()
      if isNotificationAuthorized {
        await rescheduleReminders()
      }
    } catch {
      statusMessage = error.localizedDescription
    }
  }

  func save(settings newSettings: CueSettings) async -> Bool {
    let errors = CueSettingsValidator.errors(for: newSettings)
    guard errors.isEmpty else {
      statusMessage = errors.joined(separator: "\n")
      return false
    }

    do {
      try settingsRepository.save(newSettings)
      settings = settingsRepository.settings
      await rescheduleReminders()
      sendLatestSettings()
      return true
    } catch {
      statusMessage = "Could not save settings: \(error.localizedDescription)"
      return false
    }
  }

  func rescheduleReminders() async {
    guard isNotificationAuthorized else {
      statusMessage = "Enable notifications in Settings to schedule reality-check cues."
      return
    }

    do {
      try await scheduler.scheduleDaytimeNotifications(
        settings: settings,
        startingFrom: .now
      )
      await refreshScheduleState()
      statusMessage = "Seven days of reminders are scheduled."
    } catch {
      statusMessage = "Could not schedule reminders: \(error.localizedDescription)"
    }
  }

  func record(
    result: RealityCheckEvent.Result,
    source: RealityCheckEvent.Source,
    cueWord: String? = nil
  ) {
    let event = RealityCheckEvent(
      id: UUID(),
      timestamp: .now,
      source: source,
      result: result,
      cueWord: cueWord ?? settings.cueWord
    )
    insertIfNeeded(event)
  }

  func testWatchCue() {
    do {
      try connectivity.sendTestCue()
      statusMessage = "Test cue sent to Apple Watch."
    } catch {
      statusMessage = error.localizedDescription
    }
  }

  func dismissStatus() {
    statusMessage = nil
  }

  func openSystemNotificationSettings() {
    guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else {
      return
    }
    UIApplication.shared.open(url)
  }

  #if DEBUG
  func scheduleDebugDaytimeCue() async {
    do {
      try await scheduler.scheduleTest(cueWord: settings.cueWord, after: 10)
      statusMessage = "A test notification is scheduled in 10 seconds."
      await refreshPendingIdentifiers()
    } catch {
      statusMessage = error.localizedDescription
    }
  }

  func clearPendingNotifications() async {
    scheduler.clearAllPendingNotifications()
    await refreshScheduleState()
  }

  func refreshPendingIdentifiers() async {
    pendingIdentifiers = await scheduler.pendingIdentifiers()
  }
  #endif

  var isNotificationAuthorized: Bool {
    authorizationStatus == .authorized || authorizationStatus == .provisional
  }

  private func configureNotificationDelegate() {
    notificationDelegate.didOpenRealityCheck = { [weak self] source in
      self?.route = .realityCheck(source: source)
    }
    notificationDelegate.didChooseResult = { [weak self] result, cueWord in
      self?.record(result: result, source: .iPhoneNotification, cueWord: cueWord)
    }
    notificationDelegate.didChooseSnooze = { [weak self] cueWord in
      guard let self else { return }
      Task {
        do {
          try await scheduler.scheduleSnooze(cueWord: cueWord, after: 600)
          statusMessage = "Reminder snoozed for 10 minutes."
        } catch {
          statusMessage = error.localizedDescription
        }
      }
    }
  }

  private func configureConnectivity() {
    connectivity.receivedEvent = { [weak self] event in
      self?.insertIfNeeded(event)
    }
  }

  private func insertIfNeeded(_ event: RealityCheckEvent) {
    let id = event.id
    let descriptor = FetchDescriptor<StoredRealityCheckEvent>(
      predicate: #Predicate { $0.id == id }
    )
    let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    guard existingCount == 0 else { return }
    modelContext.insert(StoredRealityCheckEvent(event: event))
    try? modelContext.save()
  }

  private func refreshScheduleState() async {
    nextDaytimeReminder = await scheduler.nextScheduledDaytimeNotification()
    nextNightCue = DateCalculator.nextNightCueDate(settings: settings, now: .now)
    #if DEBUG
    await refreshPendingIdentifiers()
    #endif
  }

  private func sendLatestSettings() {
    do {
      try connectivity.send(settings: settings)
    } catch {
      statusMessage = "Settings are saved and will sync when Apple Watch is available."
    }
  }
}
