import Foundation

struct CueSettings: Codable, Equatable, Sendable {
  var cueWord: String
  var daytimeReminderCount: Int
  var daytimeStartMinutes: Int
  var daytimeEndMinutes: Int
  var bedtimeMinutes: Int
  var nightCueDelayHours: Int
  var isNightCueEnabled: Bool
  var wbtbWeekdays: [Int]
  var wbtbRoutineMinutes: Int
  var hasAcknowledgedWBTBSafety: Bool
  var isMorningReminderEnabled: Bool
  var morningReminderMinutes: Int
  var selectedHaptic: CueHaptic
  var isSoundEnabled: Bool
  var isEnabled: Bool

  static let defaultValue = CueSettings(
    cueWord: "Dream",
    daytimeReminderCount: 4,
    daytimeStartMinutes: 9 * 60,
    daytimeEndMinutes: 21 * 60,
    bedtimeMinutes: 23 * 60,
    nightCueDelayHours: 5,
    isNightCueEnabled: true,
    wbtbWeekdays: [2, 5],
    wbtbRoutineMinutes: 5,
    hasAcknowledgedWBTBSafety: false,
    isMorningReminderEnabled: true,
    morningReminderMinutes: 8 * 60,
    selectedHaptic: .notification,
    isSoundEnabled: false,
    isEnabled: true
  )
}
