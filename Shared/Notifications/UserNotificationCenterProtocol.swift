import UserNotifications

protocol UserNotificationCenterProtocol {
  func add(_ request: UNNotificationRequest) async throws
  func pendingNotificationRequests() async -> [UNNotificationRequest]
  func removePendingNotificationRequests(withIdentifiers identifiers: [String])
  func setNotificationCategories(_ categories: Set<UNNotificationCategory>)
}

extension UNUserNotificationCenter: UserNotificationCenterProtocol {}
