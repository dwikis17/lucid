import Foundation
import Testing
import UserNotifications
@testable import lucid

struct DaytimeNotificationSchedulerTests {
  private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
  }

  private var start: Date {
    get throws {
      try #require(
        calendar.date(from: DateComponents(year: 2026, month: 7, day: 29, hour: 8))
      )
    }
  }

  @Test
  func schedulesRepeatingWeeklyPatternAndRegistersActions() async throws {
    let center = FakeNotificationCenter()
    let scheduler = DaytimeNotificationScheduler(center: center, calendar: calendar)

    scheduler.registerCategory()
    try await scheduler.reconcileDaytimeNotifications(
      settings: .defaultValue,
      startingFrom: start
    )

    #expect(center.requests.count == 28)
    let triggers = center.requests.compactMap {
      $0.trigger as? UNCalendarNotificationTrigger
    }
    #expect(triggers.count == 28)
    #expect(triggers.allSatisfy { $0.repeats })
    #expect(
      Dictionary(grouping: triggers, by: \.dateComponents.weekday)
        .values
        .allSatisfy { $0.count == 4 }
    )
    #expect(
      triggers.allSatisfy {
        $0.dateComponents.year == nil &&
          $0.dateComponents.month == nil &&
          $0.dateComponents.day == nil
      }
    )

    let category = try #require(
      center.categories.first { $0.identifier == NotificationIdentifiers.category }
    )
    #expect(category.actions.map(\.identifier) == [
      NotificationActionIdentifiers.checked,
      NotificationActionIdentifiers.snooze,
      NotificationActionIdentifiers.skip,
    ])
  }

  @Test
  func weeklyPatternIsStableAcrossWeeks() async throws {
    let firstCenter = FakeNotificationCenter()
    let secondCenter = FakeNotificationCenter()
    let firstScheduler = DaytimeNotificationScheduler(center: firstCenter, calendar: calendar)
    let secondScheduler = DaytimeNotificationScheduler(center: secondCenter, calendar: calendar)
    let laterStart = try #require(calendar.date(byAdding: .day, value: 14, to: start))

    try await firstScheduler.reconcileDaytimeNotifications(
      settings: .defaultValue,
      startingFrom: start
    )
    try await secondScheduler.reconcileDaytimeNotifications(
      settings: .defaultValue,
      startingFrom: laterStart
    )

    #expect(schedule(from: firstCenter.requests) == schedule(from: secondCenter.requests))
  }

  @Test(arguments: [3, 4, 5])
  func schedulesConfiguredCountForEveryWeekday(_ reminderCount: Int) async throws {
    let center = FakeNotificationCenter()
    let scheduler = DaytimeNotificationScheduler(center: center, calendar: calendar)
    var settings = CueSettings.defaultValue
    settings.daytimeReminderCount = reminderCount

    try await scheduler.reconcileDaytimeNotifications(
      settings: settings,
      startingFrom: start
    )

    let triggers = center.requests.compactMap {
      $0.trigger as? UNCalendarNotificationTrigger
    }
    #expect(triggers.count == reminderCount * 7)
    #expect(
      Dictionary(grouping: triggers, by: \.dateComponents.weekday)
        .values
        .allSatisfy { $0.count == reminderCount }
    )
  }

  @Test
  func reconciliationRemovesStaleRequestsWithoutDuplicates() async throws {
    let center = FakeNotificationCenter()
    let scheduler = DaytimeNotificationScheduler(center: center, calendar: calendar)
    let stale = UNNotificationRequest(
      identifier: "\(NotificationIdentifiers.daytimePrefix)2026-7-29-0",
      content: UNMutableNotificationContent(),
      trigger: nil
    )
    try await center.add(stale)

    try await scheduler.reconcileDaytimeNotifications(
      settings: .defaultValue,
      startingFrom: start
    )
    try await scheduler.reconcileDaytimeNotifications(
      settings: .defaultValue,
      startingFrom: start
    )

    #expect(center.requests.count == 28)
    #expect(Set(center.requests.map(\.identifier)).count == 28)
    #expect(!center.requests.contains { $0.identifier == stale.identifier })
  }

  @Test
  func failedReplacementPreservesPreviousSchedule() async throws {
    let center = FakeNotificationCenter()
    let scheduler = DaytimeNotificationScheduler(center: center, calendar: calendar)
    try await scheduler.reconcileDaytimeNotifications(
      settings: .defaultValue,
      startingFrom: start
    )
    let originalIdentifiers = Set(center.requests.map(\.identifier))
    center.failOnAddCall = 34
    var changedSettings = CueSettings.defaultValue
    changedSettings.cueWord = "Awake"

    await #expect(throws: FakeNotificationError.self) {
      try await scheduler.reconcileDaytimeNotifications(
        settings: changedSettings,
        startingFrom: start
      )
    }

    #expect(Set(center.requests.map(\.identifier)) == originalIdentifiers)
  }

  @Test
  func disablingRemindersCancelsDaytimeRequests() async throws {
    let center = FakeNotificationCenter()
    let scheduler = DaytimeNotificationScheduler(center: center, calendar: calendar)
    try await scheduler.reconcileDaytimeNotifications(
      settings: .defaultValue,
      startingFrom: start
    )
    var disabledSettings = CueSettings.defaultValue
    disabledSettings.isEnabled = false

    try await scheduler.reconcileDaytimeNotifications(
      settings: disabledSettings,
      startingFrom: start
    )

    #expect(center.requests.isEmpty)
  }

  private func schedule(
    from requests: [UNNotificationRequest]
  ) -> [String: DateComponents] {
    Dictionary(
      uniqueKeysWithValues: requests.compactMap { request in
        guard
          let trigger = request.trigger as? UNCalendarNotificationTrigger,
          let weekday = trigger.dateComponents.weekday
        else { return nil }
        let index = request.identifier.split(separator: ".").last ?? ""
        return ("\(weekday).\(index)", trigger.dateComponents)
      }
    )
  }
}
