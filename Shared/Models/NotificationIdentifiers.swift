import Foundation

enum NotificationIdentifiers {
  static let daytimePrefix = "lucidcue.daytime."
  static let nighttime = "lucidcue.nighttime"
  static let test = "lucidcue.test"
  static let category = "REALITY_CHECK"
}

enum NotificationActionIdentifiers {
  static let checked = "REALITY_CHECKED"
  static let snooze = "REALITY_CHECK_SNOOZE"
  static let skip = "REALITY_CHECK_SKIP"
}
