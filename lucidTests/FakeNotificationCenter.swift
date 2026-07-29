import UserNotifications
@testable import lucid

final class FakeNotificationCenter: UserNotificationCenterProtocol, @unchecked Sendable {
  private(set) var requests: [UNNotificationRequest] = []
  private(set) var categories: Set<UNNotificationCategory> = []

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

  func removeAllPendingNotificationRequests() {
    requests.removeAll()
  }

  func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
    self.categories = categories
  }
}
