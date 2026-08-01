import Foundation

enum CueSettingsValidator {
  static func errors(for settings: CueSettings) -> [String] {
    var errors: [String] = []
    let cueWord = settings.cueWord.trimmingCharacters(in: .whitespacesAndNewlines)

    if cueWord.isEmpty {
      errors.append("Enter a cue word.")
    }
    if cueWord.count > 20 {
      errors.append("Keep the cue word to 20 characters or fewer.")
    }
    if settings.cueWord.contains(where: \.isNewline) {
      errors.append("The cue word cannot contain a new line.")
    }
    if !(3...5).contains(settings.daytimeReminderCount) {
      errors.append("Choose 3, 4, or 5 daytime reminders.")
    }
    if settings.daytimeEndMinutes - settings.daytimeStartMinutes < 6 * 60 {
      errors.append("The daytime window must be at least 6 hours.")
    }
    if ![4, 5, 6].contains(settings.nightCueDelayHours) {
      errors.append("Choose a night delay of 4, 5, or 6 hours.")
    }
    if settings.wbtbWeekdays.count > 2 {
      errors.append("Choose up to two WBTB nights.")
    }
    if settings.wbtbWeekdays.contains(where: { !(1...7).contains($0) }) {
      errors.append("Choose valid WBTB weekdays.")
    }
    if ![5, 10].contains(settings.wbtbRoutineMinutes) {
      errors.append("Choose a 5- or 10-minute WBTB routine.")
    }
    if !(0..<(24 * 60)).contains(settings.morningReminderMinutes) {
      errors.append("Choose a valid morning reminder time.")
    }

    return errors
  }

  static func normalized(_ settings: CueSettings) -> CueSettings {
    var result = settings
    result.cueWord = settings.cueWord.trimmingCharacters(in: .whitespacesAndNewlines)
    return result
  }
}
