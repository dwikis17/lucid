@preconcurrency import UserNotifications

@MainActor
final class WatchNotificationDelegate:
  NSObject,
  @preconcurrency UNUserNotificationCenterDelegate
{
  var didOpenNightCue: (() -> Void)?

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else {
      return
    }
    didOpenNightCue?()
  }
}
