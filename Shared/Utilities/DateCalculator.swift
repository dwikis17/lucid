import Foundation

enum DateCalculator {
  /// Produces one stable weekly reminder in each portion of the configured window.
  ///
  /// The seed is based on the weekday and cue word, so rebuilding repeating
  /// notifications does not move reminders around unexpectedly.
  static func generateReminderDates(
    for day: Date,
    settings: CueSettings,
    calendar: Calendar = .current,
    excludingPastDatesBefore now: Date? = nil
  ) -> [Date] {
    guard settings.isEnabled, (3...5).contains(settings.daytimeReminderCount) else {
      return []
    }

    let startOfDay = calendar.startOfDay(for: day)
    let windowMinutes = settings.daytimeEndMinutes - settings.daytimeStartMinutes
    guard windowMinutes >= settings.daytimeReminderCount else { return [] }

    let segmentLength = windowMinutes / settings.daytimeReminderCount
    var generator = SeededGenerator(
      seed: seed(for: startOfDay, settings: settings, calendar: calendar)
    )
    var minuteValues: [Int] = []

    for index in 0..<settings.daytimeReminderCount {
      let segmentStart = settings.daytimeStartMinutes + index * segmentLength
      let lowerInset = min(10, max(0, segmentLength / 5))
      let available = max(1, segmentLength - lowerInset * 2)
      let offset = lowerInset + Int(generator.next() % UInt64(available))
      var minutes = min(settings.daytimeEndMinutes, segmentStart + offset)
      if let previous = minuteValues.last {
        minutes = max(minutes, previous + 90)
      }
      minuteValues.append(minutes)
    }

    if let last = minuteValues.last, last > settings.daytimeEndMinutes {
      let overflow = last - settings.daytimeEndMinutes
      minuteValues = minuteValues.map { $0 - overflow }
    }

    return minuteValues
      .compactMap { minutes in
        calendar.date(byAdding: .minute, value: minutes, to: startOfDay)
      }
      .filter { date in now.map { date > $0 } ?? true }
      .sorted()
  }

  /// Calculates the next fixed local cue time derived from bedtime plus delay.
  ///
  /// This matches a repeating calendar notification: local clock time is preserved
  /// across time-zone and daylight-saving changes, not exact elapsed duration.
  static func nextNightCueDate(
    settings: CueSettings,
    now: Date,
    calendar: Calendar = .current
  ) -> Date? {
    guard settings.isEnabled, settings.isNightCueEnabled else { return nil }

    let startOfToday = calendar.startOfDay(for: now)
    let cueMinutes = nightCueMinutes(settings: settings)
    guard
      let cueToday = calendar.date(byAdding: .minute, value: cueMinutes, to: startOfToday)
    else { return nil }

    if cueToday > now {
      return cueToday
    }
    return calendar.date(byAdding: .day, value: 1, to: cueToday)
  }

  static func nightCueMinutes(settings: CueSettings) -> Int {
    (settings.bedtimeMinutes + settings.nightCueDelayHours * 60) % (24 * 60)
  }

  private static func seed(
    for date: Date,
    settings: CueSettings,
    calendar: Calendar
  ) -> UInt64 {
    let weekday = calendar.component(.weekday, from: date)
    let value = "\(weekday)-\(settings.cueWord)"
    return value.utf8.reduce(14_695_981_039_346_656_037) { partial, byte in
      (partial ^ UInt64(byte)) &* 1_099_511_628_211
    }
  }
}

private struct SeededGenerator: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
  }

  mutating func next() -> UInt64 {
    state &+= 0x9E3779B97F4A7C15
    var value = state
    value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
    value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
    return value ^ (value >> 31)
  }
}
