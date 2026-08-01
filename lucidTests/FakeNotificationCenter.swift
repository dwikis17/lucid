import UserNotifications
@testable import lucid

final class FakeNotificationCenter: UserNotificationCenterProtocol, @unchecked Sendable {
  private(set) var requests: [UNNotificationRequest] = []
  private(set) var categories: Set<UNNotificationCategory> = []
  var failOnAddCall: Int?
  private var addCallCount = 0

  func add(_ request: UNNotificationRequest) async throws {
    addCallCount += 1
    if addCallCount == failOnAddCall {
      throw FakeNotificationError.addFailed
    }
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

enum FakeNotificationError: Error {
  case addFailed
}
