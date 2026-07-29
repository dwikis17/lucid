import Foundation
import UserNotifications

protocol NightNotificationScheduling {
  func scheduleNextNightCue(settings: CueSettings, from date: Date) async throws
  func cancelNightCue()
  func nextScheduledNightCue() async -> Date?
  func scheduleTest(settings: CueSettings, after seconds: TimeInterval) async throws
  func pendingIdentifiers() async -> [String]
  func clearAllPendingNotifications()
}

struct WatchNotificationScheduler: NightNotificationScheduling {
  private let center: UNUserNotificationCenter
  private let calendar: Calendar

  init(
    center: UNUserNotificationCenter = .current(),
    calendar: Calendar = .current
  ) {
    self.center = center
    self.calendar = calendar
  }

  /// Keeps exactly one Lucid Cue nighttime request on the watch.
  ///
  /// This is a system notification. Its exact delivery time and haptic cannot be
  /// guaranteed while the app is closed.
  func scheduleNextNightCue(settings: CueSettings, from date: Date) async throws {
    cancelNightCue()
    guard
      let cueDate = DateCalculator.nextNightCueDate(
        settings: settings,
        now: date,
        calendar: calendar
      )
    else {
      return
    }

    let content = content(for: settings)
    let components = calendar.dateComponents(
      [.year, .month, .day, .hour, .minute],
      from: cueDate
    )
    try await center.add(
      UNNotificationRequest(
        identifier: NotificationIdentifiers.nighttime,
        content: content,
        trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
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

  func scheduleTest(
    settings: CueSettings,
    after seconds: TimeInterval = 15
  ) async throws {
    try await center.add(
      UNNotificationRequest(
        identifier: NotificationIdentifiers.test,
        content: content(for: settings),
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
      )
    )
  }

  func pendingIdentifiers() async -> [String] {
    await center.pendingNotificationRequests().map(\.identifier).sorted()
  }

  func clearAllPendingNotifications() {
    center.removeAllPendingNotificationRequests()
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
