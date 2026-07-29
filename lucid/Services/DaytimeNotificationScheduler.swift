import Foundation
import UserNotifications

protocol UserNotificationCenterProtocol {
  func add(_ request: UNNotificationRequest) async throws
  func pendingNotificationRequests() async -> [UNNotificationRequest]
  func removePendingNotificationRequests(withIdentifiers identifiers: [String])
  func removeAllPendingNotificationRequests()
  func setNotificationCategories(_ categories: Set<UNNotificationCategory>)
}

extension UNUserNotificationCenter: UserNotificationCenterProtocol {}

protocol DaytimeNotificationScheduling {
  func registerCategory()
  func scheduleDaytimeNotifications(
    settings: CueSettings,
    startingFrom date: Date
  ) async throws
  func cancelDaytimeNotifications() async
  func nextScheduledDaytimeNotification() async -> Date?
  func scheduleSnooze(cueWord: String, after seconds: TimeInterval) async throws
  func scheduleTest(cueWord: String, after seconds: TimeInterval) async throws
  func pendingIdentifiers() async -> [String]
  func clearAllPendingNotifications()
}

struct DaytimeNotificationScheduler: DaytimeNotificationScheduling {
  private let center: any UserNotificationCenterProtocol
  private let calendar: Calendar

  init(
    center: any UserNotificationCenterProtocol = UNUserNotificationCenter.current(),
    calendar: Calendar = .current
  ) {
    self.center = center
    self.calendar = calendar
  }

  func registerCategory() {
    let checked = UNNotificationAction(
      identifier: NotificationActionIdentifiers.checked,
      title: "Checked"
    )
    let snooze = UNNotificationAction(
      identifier: NotificationActionIdentifiers.snooze,
      title: "Remind me in 10 minutes"
    )
    let skip = UNNotificationAction(
      identifier: NotificationActionIdentifiers.skip,
      title: "Skip"
    )
    let category = UNNotificationCategory(
      identifier: NotificationIdentifiers.category,
      actions: [checked, snooze, skip],
      intentIdentifiers: []
    )
    center.setNotificationCategories([category])
  }

  /// Replaces only Lucid Cue daytime requests with seven deterministic local days.
  ///
  /// Pending requests are intentionally bounded to 35 or fewer. Delivery remains
  /// subject to Focus, notification settings, and system power management.
  func scheduleDaytimeNotifications(
    settings: CueSettings,
    startingFrom date: Date
  ) async throws {
    await cancelDaytimeNotifications()
    guard settings.isEnabled else { return }

    for dayOffset in 0..<7 {
      guard let day = calendar.date(byAdding: .day, value: dayOffset, to: date) else {
        continue
      }
      let dates = DateCalculator.generateReminderDates(
        for: day,
        settings: settings,
        calendar: calendar,
        excludingPastDatesBefore: date
      )

      for (index, reminderDate) in dates.enumerated() {
        let identifier = identifier(for: reminderDate, index: index)
        let content = notificationContent(
          title: settings.cueWord,
          body: "Pause for a moment. Are you dreaming?",
          cueWord: settings.cueWord,
          isSoundEnabled: settings.isSoundEnabled
        )
        let components = calendar.dateComponents(
          [.year, .month, .day, .hour, .minute],
          from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(
          dateMatching: components,
          repeats: false
        )
        try await center.add(
          UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
          )
        )
      }
    }
  }

  func cancelDaytimeNotifications() async {
    let identifiers = await pendingIdentifiers()
      .filter { $0.hasPrefix(NotificationIdentifiers.daytimePrefix) }
    center.removePendingNotificationRequests(withIdentifiers: identifiers)
  }

  func nextScheduledDaytimeNotification() async -> Date? {
    let requests = await center.pendingNotificationRequests()
    return requests
      .filter { $0.identifier.hasPrefix(NotificationIdentifiers.daytimePrefix) }
      .compactMap { ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() }
      .filter { $0 > Date.now }
      .min()
  }

  func scheduleSnooze(cueWord: String, after seconds: TimeInterval = 600) async throws {
    let content = notificationContent(
      title: "Reality check",
      body: "Take another look. Does anything feel unusual?",
      cueWord: cueWord,
      isSoundEnabled: false
    )
    try await center.add(
      UNNotificationRequest(
        identifier: "\(NotificationIdentifiers.test).snooze.\(UUID().uuidString)",
        content: content,
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
      )
    )
  }

  func scheduleTest(cueWord: String, after seconds: TimeInterval = 10) async throws {
    let content = notificationContent(
      title: cueWord,
      body: "Test cue: are you dreaming?",
      cueWord: cueWord,
      isSoundEnabled: false
    )
    try await center.add(
      UNNotificationRequest(
        identifier: NotificationIdentifiers.test,
        content: content,
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
      )
    )
  }

  func pendingIdentifiers() async -> [String] {
    await center.pendingNotificationRequests()
      .map(\.identifier)
      .sorted()
  }

  func clearAllPendingNotifications() {
    center.removeAllPendingNotificationRequests()
  }

  private func identifier(for date: Date, index: Int) -> String {
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    return "\(NotificationIdentifiers.daytimePrefix)" +
      "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)-\(index)"
  }

  private func notificationContent(
    title: String,
    body: String,
    cueWord: String,
    isSoundEnabled: Bool
  ) -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.categoryIdentifier = NotificationIdentifiers.category
    content.userInfo = [
      "type": "daytimeRealityCheck",
      "cueWord": cueWord,
    ]
    content.sound = isSoundEnabled ? .default : nil
    return content
  }
}
