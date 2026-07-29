import UserNotifications

protocol NotificationAuthorizing {
  func requestAuthorization() async throws -> Bool
  func authorizationStatus() async -> UNAuthorizationStatus
}

struct NotificationAuthorizationService: NotificationAuthorizing {
  func requestAuthorization() async throws -> Bool {
    try await UNUserNotificationCenter.current()
      .requestAuthorization(options: [.alert, .sound])
  }

  func authorizationStatus() async -> UNAuthorizationStatus {
    await UNUserNotificationCenter.current()
      .notificationSettings()
      .authorizationStatus
  }
}
