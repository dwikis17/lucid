import Foundation
import UserNotifications

protocol NightNotificationScheduling {
  func reconcileNightCue(settings: CueSettings) async throws
  func cancelNightCue()
  func nextScheduledNightCue() async -> Date?
}

struct WatchNotificationScheduler: NightNotificationScheduling {
  private let center: any UserNotificationCenterProtocol

  init(center: any UserNotificationCenterProtocol = UNUserNotificationCenter.current()) {
    self.center = center
  }

  /// Keeps one repeating Lucid Cue nighttime request on the watch.
  ///
  /// This is a system notification. Its exact delivery time and haptic cannot be
  /// guaranteed while the app is closed.
  func reconcileNightCue(settings: CueSettings) async throws {
    guard settings.isEnabled, settings.isNightCueEnabled else {
      cancelNightCue()
      return
    }

    let cueMinutes = DateCalculator.nightCueMinutes(settings: settings)
    let trigger = UNCalendarNotificationTrigger(
      dateMatching: DateComponents(hour: cueMinutes / 60, minute: cueMinutes % 60),
      repeats: true
    )
    try await center.add(
      UNNotificationRequest(
        identifier: NotificationIdentifiers.nighttime,
        content: content(for: settings),
        trigger: trigger
      )
    )
  }

  func cancelNightCue() {
    center.removePendingNotificationRequests(
      withIdentifiers: [NotificationIdentifiers.nighttime]
    )
  }

  func nextScheduledNightCue() async -> Date? {
    await center.pendingNotificationRequests()
      .first { $0.identifier == NotificationIdentifiers.nighttime }
      .flatMap { ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() }
  }

  private func content(for settings: CueSettings) -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    content.title = settings.cueWord
    content.body = "Notice this moment. Are you dreaming?"
    content.userInfo = [
      "type": "nighttimeRealityCheck",
      "cueWord": settings.cueWord,
    ]
    content.sound = settings.isSoundEnabled ? .default : nil
    return content
  }
}
