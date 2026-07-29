import Foundation

struct CueSettings: Codable, Equatable, Sendable {
  var cueWord: String
  var daytimeReminderCount: Int
  var daytimeStartMinutes: Int
  var daytimeEndMinutes: Int
  var bedtimeMinutes: Int
  var nightCueDelayHours: Int
  var isNightCueEnabled: Bool
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
    selectedHaptic: .notification,
    isSoundEnabled: false,
    isEnabled: true
  )
}
