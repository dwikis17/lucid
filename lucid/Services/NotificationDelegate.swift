@preconcurrency import UserNotifications

@MainActor
final class NotificationDelegate:
  NSObject,
  @preconcurrency UNUserNotificationCenterDelegate
{
  var didOpenRealityCheck: ((RealityCheckEvent.Source) -> Void)?
  var didOpenMorningJournal: (() -> Void)?
  var didOpenWBTB: (() -> Void)?
  var didChooseResult: ((RealityCheckEvent.Result, String) -> Void)?
  var didChooseSnooze: ((String) -> Void)?

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    [.banner, .sound]
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    let cueWord = response.notification.request.content.userInfo["cueWord"] as? String
      ?? CueSettings.defaultValue.cueWord
    let type = response.notification.request.content.userInfo["type"] as? String

    if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
      switch type {
      case "morningJournal":
        didOpenMorningJournal?()
      case "wbtb":
        didOpenWBTB?()
      default:
        didOpenRealityCheck?(.iPhoneNotification)
      }
      return
    }

    switch response.actionIdentifier {
    case NotificationActionIdentifiers.checked:
      didChooseResult?(.completed, cueWord)
    case NotificationActionIdentifiers.skip:
      didChooseResult?(.skipped, cueWord)
    case NotificationActionIdentifiers.snooze:
      didChooseSnooze?(cueWord)
    default:
      break
    }
  }
}
