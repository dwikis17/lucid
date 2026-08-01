import Foundation
import Observation
import SwiftData
import UIKit
import UserNotifications

@MainActor
@Observable
final class AppModel {
  private(set) var settings: CueSettings
  private(set) var isWBTBAlarmEnabled: Bool
  private(set) var authorizationStatus = UNAuthorizationStatus.notDetermined
  private(set) var nextDaytimeReminder: Date?
  private(set) var nextNightCue: Date?
  private(set) var isTestWBTBAlarmScheduled = false
  private(set) var testWBTBAlarmStatus: String?
  private(set) var statusMessage: String?
  var route: AppRoute?
  let appLock: AppLockManager
  let purchaseManager: PurchaseManager

  private let settingsRepository: SettingsRepository
  private let scheduler: any DaytimeNotificationScheduling
  private let authorizationService: any NotificationAuthorizing
  private let modelContext: ModelContext
  private let notificationDelegate: NotificationDelegate
  private let connectivity: IOSConnectivityService

  init(
    modelContext: ModelContext,
    settingsRepository: SettingsRepository = SettingsRepository(),
    scheduler: any DaytimeNotificationScheduling = DaytimeNotificationScheduler(),
    authorizationService: any NotificationAuthorizing = NotificationAuthorizationService(),
    connectivity: IOSConnectivityService = IOSConnectivityService(),
    appLock: AppLockManager = AppLockManager(),
    purchaseManager: PurchaseManager = PurchaseManager()
  ) {
    self.modelContext = modelContext
    self.settingsRepository = settingsRepository
    self.scheduler = scheduler
    self.authorizationService = authorizationService
    self.connectivity = connectivity
    self.appLock = appLock
    self.purchaseManager = purchaseManager
    settings = settingsRepository.settings
    isWBTBAlarmEnabled = settingsRepository.isWBTBAlarmEnabled
    notificationDelegate = NotificationDelegate()

    configureNotificationDelegate()
    configureConnectivity()
    scheduler.registerCategory()
    UNUserNotificationCenter.current().delegate = notificationDelegate
    connectivity.activate()
  }

  func didLaunch() async {
    await purchaseManager.start()
    await reconcileNotificationState()
    consumeWBTBAlarmRoute()
    sendLatestSettings()
  }

  func didBecomeActive() async {
    await purchaseManager.refresh()
    await reconcileNotificationState()
    consumeWBTBAlarmRoute()
    sendLatestSettings()
  }

  func requestNotificationPermission() async {
    do {
      _ = try await authorizationService.requestAuthorization()
      await reconcileNotificationState()
    } catch {
      statusMessage = error.localizedDescription
    }
  }

  func scheduleTestWBTBAlarm() async {
    isTestWBTBAlarmScheduled = false
    guard purchaseManager.isPro else {
      setTestWBTBAlarmStatus("Lucid Pro is required to test the WBTB alarm.")
      return
    }
    guard settings.hasAcknowledgedWBTBSafety else {
      setTestWBTBAlarmStatus("Acknowledge the WBTB safety notice in Cue Schedule first.")
      return
    }
    if #unavailable(iOS 26.0), !isNotificationAuthorized {
      setTestWBTBAlarmStatus("Enable notifications in Settings to test the WBTB alarm.")
      return
    }

    do {
      try await scheduler.scheduleTestWBTBAlarm()
      isTestWBTBAlarmScheduled = true
      setTestWBTBAlarmStatus("Test WBTB alarm scheduled for about 10 seconds from now.")
    } catch WBTBAlarmError.authorizationDenied {
      setTestWBTBAlarmStatus("Alarm permission is off. Enable alarms in Settings to test this flow.")
    } catch {
      setTestWBTBAlarmStatus("Could not schedule the test alarm: \(error.localizedDescription)")
    }
  }

  func cancelTestWBTBAlarm() {
    scheduler.cancelTestWBTBAlarm()
    isTestWBTBAlarmScheduled = false
    setTestWBTBAlarmStatus("Test WBTB alarm cancelled.")
  }

  func save(settings newSettings: CueSettings, isWBTBAlarmEnabled newAlarmEnabled: Bool? = nil) async -> Bool {
    let errors = CueSettingsValidator.errors(for: newSettings)
    guard errors.isEmpty else {
      statusMessage = errors.joined(separator: "\n")
      return false
    }

    do {
      try settingsRepository.save(
        newSettings,
        isWBTBAlarmEnabled: newAlarmEnabled ?? isWBTBAlarmEnabled
      )
      settings = settingsRepository.settings
      isWBTBAlarmEnabled = settingsRepository.isWBTBAlarmEnabled
      await reconcileReminders()
      sendLatestSettings()
      return !(newAlarmEnabled == true && !isWBTBAlarmEnabled)
    } catch {
      statusMessage = "Could not save settings: \(error.localizedDescription)"
      return false
    }
  }

  private func reconcileReminders() async {
    do {
      if isNotificationAuthorized {
        if purchaseManager.isPro {
          try await scheduler.reconcileDaytimeNotifications(settings: settings, startingFrom: .now)
        } else {
          await scheduler.cancelDaytimeNotifications()
        }
        try await scheduler.reconcileMorningJournalReminder(settings: settings)
      } else {
        await scheduler.cancelDaytimeNotifications()
      }

      if purchaseManager.isPro {
        try await scheduler.reconcileWBTBNotifications(
          settings: settings,
          alarmEnabled: isWBTBAlarmEnabled
        )
      } else {
        var freeSettings = settings
        freeSettings.isNightCueEnabled = false
        try await scheduler.reconcileWBTBNotifications(
          settings: freeSettings,
          alarmEnabled: false
        )
      }
      await refreshScheduleState()

      let alarmCanRunWithoutNotifications = if #available(iOS 26.0, *) {
        isWBTBAlarmEnabled
      } else {
        false
      }
      if !isNotificationAuthorized && !alarmCanRunWithoutNotifications {
        statusMessage = "Enable notifications in Settings to schedule reality-check and WBTB cues."
      }
    } catch WBTBAlarmError.authorizationDenied {
      isWBTBAlarmEnabled = false
      try? settingsRepository.save(settings, isWBTBAlarmEnabled: false)
      statusMessage = "Alarm permission is off. Gentle WBTB cues remain enabled."
      do {
        try await scheduler.reconcileWBTBNotifications(settings: settings, alarmEnabled: false)
      } catch {
        statusMessage = "Could not schedule WBTB cues: \(error.localizedDescription)"
      }
      await refreshScheduleState()
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

  func beginDreamEntry() {
    let dream = DreamEntry()
    modelContext.insert(dream)
    try? modelContext.save()
    route = .dreamEntry(id: dream.id)
  }

  func dreamEntry(id: UUID) -> DreamEntry? {
    let descriptor = FetchDescriptor<DreamEntry>(
      predicate: #Predicate { $0.id == id }
    )
    return try? modelContext.fetch(descriptor).first
  }

  func recordWBTBSession() {
    modelContext.insert(StoredWBTBSession(routineMinutes: settings.wbtbRoutineMinutes))
    try? modelContext.save()
  }

  func dismissStatus() {
    statusMessage = nil
  }

  func setAppLockEnabled(_ enabled: Bool) {
    appLock.setEnabled(enabled)
  }

  func openSystemNotificationSettings() {
    guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else {
      return
    }
    UIApplication.shared.open(url)
  }

  var isNotificationAuthorized: Bool {
    authorizationStatus == .authorized || authorizationStatus == .provisional
  }

  private func configureNotificationDelegate() {
    notificationDelegate.didOpenRealityCheck = { [weak self] source in
      self?.route = .realityCheck(source: source)
    }
    notificationDelegate.didOpenMorningJournal = { [weak self] in
      self?.beginDreamEntry()
    }
    notificationDelegate.didOpenWBTB = { [weak self] in
      self?.route = .wbtb
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
    nextDaytimeReminder = if settings.isEnabled && isNotificationAuthorized {
      await scheduler.nextScheduledDaytimeNotification()
    } else {
      nil
    }
    nextNightCue = if purchaseManager.isPro,
      settings.isNightCueEnabled,
      settings.hasAcknowledgedWBTBSafety,
      !settings.wbtbWeekdays.isEmpty
    {
      DateCalculator.nextNightCueDate(settings: settings, now: .now)
    } else {
      nil
    }
  }

  private func reconcileNotificationState() async {
    authorizationStatus = await authorizationService.authorizationStatus()
    await reconcileReminders()
  }

  private func consumeWBTBAlarmRoute() {
    guard UserDefaults.standard.bool(forKey: WBTBAlarmService.openWBTBKey) else { return }
    UserDefaults.standard.removeObject(forKey: WBTBAlarmService.openWBTBKey)
    isTestWBTBAlarmScheduled = false
    route = .wbtb
  }

  private func setTestWBTBAlarmStatus(_ message: String) {
    testWBTBAlarmStatus = message
    statusMessage = message
  }

  private func sendLatestSettings() {
    var watchSettings = settings
    if !purchaseManager.isPro {
      watchSettings.isNightCueEnabled = false
      watchSettings.wbtbWeekdays = []
    }
    try? connectivity.send(settings: watchSettings)
  }
}
