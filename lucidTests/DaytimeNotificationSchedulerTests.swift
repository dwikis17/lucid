import Foundation
import Testing
import UserNotifications
@testable import lucid

struct DaytimeNotificationSchedulerTests {
  @Test
  func schedulesSevenDaysAndRegistersActions() async throws {
    let center = FakeNotificationCenter()
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    let scheduler = DaytimeNotificationScheduler(center: center, calendar: calendar)
    let start = try #require(
      calendar.date(
        from: DateComponents(year: 2026, month: 7, day: 29, hour: 8)
      )
    )

    scheduler.registerCategory()
    try await scheduler.scheduleDaytimeNotifications(
      settings: .defaultValue,
      startingFrom: start
    )

    #expect(center.requests.count == 28)
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
  func replacingScheduleDoesNotDuplicateRequests() async throws {
    let center = FakeNotificationCenter()
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    let scheduler = DaytimeNotificationScheduler(center: center, calendar: calendar)
    let start = try #require(
      calendar.date(
        from: DateComponents(year: 2026, month: 7, day: 29, hour: 8)
      )
    )

    try await scheduler.scheduleDaytimeNotifications(
      settings: .defaultValue,
      startingFrom: start
    )
    try await scheduler.scheduleDaytimeNotifications(
      settings: .defaultValue,
      startingFrom: start
    )

    #expect(center.requests.count == 28)
    #expect(Set(center.requests.map(\.identifier)).count == 28)
  }
}
