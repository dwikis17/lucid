import Foundation
import UserNotifications

protocol DaytimeNotificationScheduling {
  func registerCategory()
  func reconcileDaytimeNotifications(
    settings: CueSettings,
    startingFrom date: Date
  ) async throws
  func cancelDaytimeNotifications() async
  func nextScheduledDaytimeNotification() async -> Date?
  func scheduleSnooze(cueWord: String, after seconds: TimeInterval) async throws
  func reconcileWBTBNotifications(settings: CueSettings) async throws
  func reconcileWBTBNotifications(settings: CueSettings, alarmEnabled: Bool) async throws
  func scheduleTestWBTBAlarm() async throws
  func cancelTestWBTBAlarm()
  func reconcileMorningJournalReminder(settings: CueSettings) async throws
}

extension DaytimeNotificationScheduling {
  func reconcileWBTBNotifications(settings: CueSettings) async throws {}
  func reconcileWBTBNotifications(settings: CueSettings, alarmEnabled: Bool) async throws {
    try await reconcileWBTBNotifications(settings: settings)
  }
  func scheduleTestWBTBAlarm() async throws {}
  func cancelTestWBTBAlarm() {}
  func reconcileMorningJournalReminder(settings: CueSettings) async throws {}
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

  /// Reconciles a deterministic weekly pattern of repeating local notifications.
  ///
  /// New requests are installed before stale requests are removed, preserving the
  /// current schedule if installation fails.
  func reconcileDaytimeNotifications(
    settings: CueSettings,
    startingFrom date: Date
  ) async throws {
    guard settings.isEnabled else {
      await cancelDaytimeNotifications()
      return
    }

    let existingIdentifiers = Set(
      await center.pendingNotificationRequests()
        .map(\.identifier)
        .filter { $0.hasPrefix(NotificationIdentifiers.daytimePrefix) }
    )
    let requests = notificationRequests(settings: settings, startingFrom: date)
    let expectedIdentifiers = Set(requests.map(\.identifier))
    var newlyAddedIdentifiers: [String] = []

    do {
      for request in requests {
        try await center.add(request)
        if !existingIdentifiers.contains(request.identifier) {
          newlyAddedIdentifiers.append(request.identifier)
        }
      }
    } catch {
      center.removePendingNotificationRequests(withIdentifiers: newlyAddedIdentifiers)
      throw error
    }

    let staleIdentifiers = Array(existingIdentifiers.subtracting(expectedIdentifiers))
    if !staleIdentifiers.isEmpty {
      center.removePendingNotificationRequests(withIdentifiers: staleIdentifiers)
    }
  }

  func cancelDaytimeNotifications() async {
    let identifiers = await center.pendingNotificationRequests()
      .map(\.identifier)
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
        identifier: "\(NotificationIdentifiers.snoozePrefix)\(UUID().uuidString)",
        content: content,
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
      )
    )
  }

  func reconcileWBTBNotifications(settings: CueSettings) async throws {
    try await reconcileWBTBNotifications(settings: settings, alarmEnabled: false)
  }

  func reconcileWBTBNotifications(settings: CueSettings, alarmEnabled: Bool) async throws {
    let existing = await center.pendingNotificationRequests()
      .map(\.identifier)
      .filter { $0.hasPrefix(NotificationIdentifiers.wbtbPrefix) }
    center.removePendingNotificationRequests(withIdentifiers: existing)
    WBTBAlarmService.cancel()

    guard
      settings.isEnabled,
      settings.isNightCueEnabled,
      settings.hasAcknowledgedWBTBSafety,
      !settings.wbtbWeekdays.isEmpty
    else { return }

    if alarmEnabled, #available(iOS 26.0, *) {
      try await WBTBAlarmService.reconcile(settings: settings)
      return
    }

    let minutes = DateCalculator.nightCueMinutes(settings: settings)
    for weekday in settings.wbtbWeekdays {
      let content = UNMutableNotificationContent()
      content.title = "Wake Back to Bed"
      content.body = "Recall a dream, set your intention, then return to sleep."
      content.userInfo = ["type": "wbtb"]
      if alarmEnabled {
        content.interruptionLevel = .timeSensitive
        content.sound = .default
      }
      try await center.add(
        UNNotificationRequest(
          identifier: "\(NotificationIdentifiers.wbtbPrefix)\(weekday)",
          content: content,
          trigger: UNCalendarNotificationTrigger(
            dateMatching: DateComponents(
              hour: minutes / 60,
              minute: minutes % 60,
              weekday: weekday
            ),
            repeats: true
          )
        )
      )
    }
  }

  func scheduleTestWBTBAlarm() async throws {
    cancelTestWBTBAlarm()
    if #available(iOS 26.0, *) {
      try await WBTBAlarmService.scheduleTestAlarm()
      return
    }

    let content = UNMutableNotificationContent()
    content.title = "Wake Back to Bed"
    content.body = "Recall a dream, set your intention, then return to sleep."
    content.sound = .default
    content.interruptionLevel = .timeSensitive
    content.userInfo = ["type": "wbtb"]
    try await center.add(
      UNNotificationRequest(
        identifier: NotificationIdentifiers.wbtbTest,
        content: content,
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
      )
    )
  }

  func cancelTestWBTBAlarm() {
    center.removePendingNotificationRequests(withIdentifiers: [NotificationIdentifiers.wbtbTest])
    WBTBAlarmService.cancelTestAlarm()
  }

  func reconcileMorningJournalReminder(settings: CueSettings) async throws {
    center.removePendingNotificationRequests(withIdentifiers: [NotificationIdentifiers.morningJournal])
    guard settings.isEnabled, settings.isMorningReminderEnabled else { return }
    let content = UNMutableNotificationContent()
    content.title = "Remember your dream"
    content.body = "Write down what you remember before it fades."
    content.userInfo = ["type": "morningJournal"]
    try await center.add(
      UNNotificationRequest(
        identifier: NotificationIdentifiers.morningJournal,
        content: content,
        trigger: UNCalendarNotificationTrigger(
          dateMatching: DateComponents(
            hour: settings.morningReminderMinutes / 60,
            minute: settings.morningReminderMinutes % 60
          ),
          repeats: true
        )
      )
    )
  }

  private func notificationRequests(
    settings: CueSettings,
    startingFrom date: Date
  ) -> [UNNotificationRequest] {
    let scheduleKey = scheduleKey(for: settings)
    let startOfDay = calendar.startOfDay(for: date)

    return (0..<7).flatMap { dayOffset -> [UNNotificationRequest] in
      guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfDay) else {
        return []
      }
      let weekday = calendar.component(.weekday, from: day)
      return DateCalculator.generateReminderDates(
        for: day,
        settings: settings,
        calendar: calendar
      )
      .enumerated()
      .map { index, reminderDate in
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: reminderDate)
        return UNNotificationRequest(
          identifier: "\(NotificationIdentifiers.daytimePrefix)" +
            "v2.\(scheduleKey).\(weekday).\(index)",
          content: notificationContent(
            title: settings.cueWord,
            body: "Pause for a moment. Are you dreaming?",
            cueWord: settings.cueWord,
            isSoundEnabled: settings.isSoundEnabled
          ),
          trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        )
      }
    }
  }

  private func scheduleKey(for settings: CueSettings) -> String {
    let value = [
      settings.cueWord,
      String(settings.daytimeReminderCount),
      String(settings.daytimeStartMinutes),
      String(settings.daytimeEndMinutes),
      settings.isSoundEnabled.description,
    ].joined(separator: "|")
    let hash = value.utf8.reduce(UInt64(14_695_981_039_346_656_037)) { partial, byte in
      (partial ^ UInt64(byte)) &* 1_099_511_628_211
    }
    return String(hash, radix: 16)
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
