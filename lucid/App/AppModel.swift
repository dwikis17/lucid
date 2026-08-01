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
    sendLatestSettings()
  }

  func didBecomeActive() async {
    await purchaseManager.refresh()
    await reconcileNotificationState()
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

  func save(settings newSettings: CueSettings) async -> Bool {
    let errors = CueSettingsValidator.errors(for: newSettings)
    guard errors.isEmpty else {
      statusMessage = errors.joined(separator: "\n")
      return false
    }

    do {
      try settingsRepository.save(newSettings)
      settings = settingsRepository.settings
      await reconcileReminders()
      sendLatestSettings()
      return true
    } catch {
      statusMessage = "Could not save settings: \(error.localizedDescription)"
      return false
    }
  }

  private func reconcileReminders() async {
    guard isNotificationAuthorized else {
      statusMessage = "Enable notifications in Settings to schedule reality-check cues."
      await refreshScheduleState()
      return
    }

    do {
      if purchaseManager.isPro {
        try await scheduler.reconcileDaytimeNotifications(settings: settings, startingFrom: .now)
      } else {
        await scheduler.cancelDaytimeNotifications()
      }
      try await scheduler.reconcileMorningJournalReminder(settings: settings)
      if purchaseManager.isPro {
        try await scheduler.reconcileWBTBNotifications(settings: settings)
      } else {
        var freeSettings = settings
        freeSettings.isNightCueEnabled = false
        try await scheduler.reconcileWBTBNotifications(settings: freeSettings)
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
    if isNotificationAuthorized {
      await reconcileReminders()
    } else {
      await refreshScheduleState()
    }
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
