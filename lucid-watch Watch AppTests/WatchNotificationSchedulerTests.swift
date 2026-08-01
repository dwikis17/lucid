import Testing
import UserNotifications
@testable import lucid_watch_Watch_App

struct WatchNotificationSchedulerTests {
  @Test
  func schedulesRepeatingNightCueAfterMidnight() async throws {
    let center = FakeWatchNotificationCenter()
    let scheduler = WatchNotificationScheduler(center: center)

    try await scheduler.reconcileNightCue(settings: .defaultValue)

    let request = try #require(center.requests.first)
    let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
    #expect(request.identifier == NotificationIdentifiers.nighttime)
    #expect(trigger.repeats)
    #expect(trigger.dateComponents.hour == 4)
    #expect(trigger.dateComponents.minute == 0)
    #expect(trigger.dateComponents.day == nil)
  }

  @Test
  func disablingNightCueCancelsExistingRequest() async throws {
    let center = FakeWatchNotificationCenter()
    let scheduler = WatchNotificationScheduler(center: center)
    try await scheduler.reconcileNightCue(settings: .defaultValue)
    var disabledSettings = CueSettings.defaultValue
    disabledSettings.isNightCueEnabled = false

    try await scheduler.reconcileNightCue(settings: disabledSettings)

    #expect(center.requests.isEmpty)
  }
}

private final class FakeWatchNotificationCenter:
  UserNotificationCenterProtocol,
  @unchecked Sendable
{
  private(set) var requests: [UNNotificationRequest] = []

  func add(_ request: UNNotificationRequest) async throws {
    requests.removeAll { $0.identifier == request.identifier }
    requests.append(request)
  }

  func pendingNotificationRequests() async -> [UNNotificationRequest] {
    requests
  }

  func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
    requests.removeAll { identifiers.contains($0.identifier) }
  }

  func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {}
}
