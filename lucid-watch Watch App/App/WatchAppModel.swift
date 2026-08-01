import Observation
import UserNotifications

@MainActor
@Observable
final class WatchAppModel {
  private(set) var settings: CueSettings
  private(set) var nextNightCue: Date?
  private(set) var statusMessage: String?
  private(set) var authorizationStatus = UNAuthorizationStatus.notDetermined
  var isShowingRealityCheck = false
  var realityCheckSource = RealityCheckEvent.Source.watchManual

  private let repository: WatchSettingsRepository
  private let scheduler: any NightNotificationScheduling
  private let hapticService: WatchHapticService
  private let notificationDelegate: WatchNotificationDelegate
  private let connectivity: WatchConnectivityService

  init(
    repository: WatchSettingsRepository = WatchSettingsRepository(),
    scheduler: any NightNotificationScheduling = WatchNotificationScheduler(),
    hapticService: WatchHapticService = WatchHapticService(),
    connectivity: WatchConnectivityService = WatchConnectivityService()
  ) {
    self.repository = repository
    self.scheduler = scheduler
    self.hapticService = hapticService
    self.connectivity = connectivity
    settings = repository.payload.settings
    notificationDelegate = WatchNotificationDelegate()

    configureConnectivity()
    notificationDelegate.didOpenNightCue = { [weak self] in
      self?.realityCheckSource = .watchNotification
      self?.isShowingRealityCheck = true
    }
    UNUserNotificationCenter.current().delegate = notificationDelegate
    connectivity.activate()
  }

  func start() async {
    authorizationStatus = await UNUserNotificationCenter.current()
      .notificationSettings()
      .authorizationStatus
    await scheduleNightCueIfAllowed()
  }

  func didBecomeActive() async {
    await start()
  }

  func showManualRealityCheck() {
    realityCheckSource = .watchManual
    isShowingRealityCheck = true
  }

  func record(
    result: RealityCheckEvent.Result,
    source: RealityCheckEvent.Source
  ) {
    if result == .completed {
      hapticService.play(settings.selectedHaptic)
    }
    let event = RealityCheckEvent(
      id: UUID(),
      timestamp: .now,
      source: source,
      result: result,
      cueWord: settings.cueWord
    )
    do {
      try connectivity.send(event: event)
      statusMessage = result == .completed ? "Check recorded" : "Skipped"
    } catch {
      statusMessage = error.localizedDescription
    }
  }

  private func configureConnectivity() {
    connectivity.receivedPayload = { [weak self] payload in
      self?.didReceive(payload)
    }
  }

  private func didReceive(_ payload: ConnectivityPayload) {
    do {
      guard try repository.saveIfNewer(payload) else { return }
      settings = repository.payload.settings
      Task {
        await requestPermissionIfNeeded()
        await scheduleNightCueIfAllowed()
      }
    } catch {
      statusMessage = "The received settings were invalid."
    }
  }

  private func requestPermissionIfNeeded() async {
    authorizationStatus = await UNUserNotificationCenter.current()
      .notificationSettings()
      .authorizationStatus
    guard authorizationStatus == .notDetermined else { return }
    do {
      _ = try await UNUserNotificationCenter.current()
        .requestAuthorization(options: [.alert, .sound])
      authorizationStatus = await UNUserNotificationCenter.current()
        .notificationSettings()
        .authorizationStatus
    } catch {
      statusMessage = error.localizedDescription
    }
  }

  private func scheduleNightCueIfAllowed() async {
    scheduler.cancelNightCue()
    nextNightCue = nil
  }
}
