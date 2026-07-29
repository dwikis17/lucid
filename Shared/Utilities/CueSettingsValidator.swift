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

    return errors
  }

  static func normalized(_ settings: CueSettings) -> CueSettings {
    var result = settings
    result.cueWord = settings.cueWord.trimmingCharacters(in: .whitespacesAndNewlines)
    return result
  }
}
