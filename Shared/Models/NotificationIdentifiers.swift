import Foundation

enum NotificationIdentifiers {
  static let daytimePrefix = "lucidcue.daytime."
  static let nighttime = "lucidcue.nighttime"
  static let wbtbPrefix = "lucidcue.wbtb."
  static let morningJournal = "lucidcue.morning-journal"
  static let snoozePrefix = "lucidcue.snooze."
  static let category = "REALITY_CHECK"
}

enum NotificationActionIdentifiers {
  static let checked = "REALITY_CHECKED"
  static let snooze = "REALITY_CHECK_SNOOZE"
  static let skip = "REALITY_CHECK_SKIP"
}
