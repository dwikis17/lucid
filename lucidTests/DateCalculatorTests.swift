import Foundation
import Testing
@testable import lucid

struct DateCalculatorTests {
  private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .gmt
    return calendar
  }

  @Test
  func reminderDatesAreStableSpacedAndInsideWindow() throws {
    let day = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 7, day: 29))
    )
    let first = DateCalculator.generateReminderDates(
      for: day,
      settings: .defaultValue,
      calendar: calendar
    )
    let second = DateCalculator.generateReminderDates(
      for: day,
      settings: .defaultValue,
      calendar: calendar
    )

    #expect(first == second)
    #expect(first.count == 4)
    #expect(zip(first, first.dropFirst()).allSatisfy { $1.timeIntervalSince($0) >= 90 * 60 })

    for date in first {
      let components = calendar.dateComponents([.hour, .minute], from: date)
      let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
      #expect((9 * 60..<21 * 60).contains(minutes))
    }
  }

  @Test
  func pastReminderDatesAreExcluded() throws {
    let day = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 7, day: 29))
    )
    let noon = try #require(calendar.date(byAdding: .hour, value: 12, to: day))
    let dates = DateCalculator.generateReminderDates(
      for: day,
      settings: .defaultValue,
      calendar: calendar,
      excludingPastDatesBefore: noon
    )

    #expect(dates.allSatisfy { $0 > noon })
    #expect(dates.count < CueSettings.defaultValue.daytimeReminderCount)
  }

  @Test
  func nightCueCrossesMidnight() throws {
    let now = try #require(
      calendar.date(
        from: DateComponents(year: 2026, month: 7, day: 29, hour: 18)
      )
    )
    let cue = try #require(
      DateCalculator.nextNightCueDate(
        settings: .defaultValue,
        now: now,
        calendar: calendar
      )
    )
    let components = calendar.dateComponents([.day, .hour], from: cue)

    #expect(components.day == 30)
    #expect(components.hour == 4)
  }

  @Test
  func passedNightCueMovesToFollowingNight() throws {
    let now = try #require(
      calendar.date(
        from: DateComponents(year: 2026, month: 7, day: 29, hour: 6)
      )
    )
    let cue = try #require(
      DateCalculator.nextNightCueDate(
        settings: .defaultValue,
        now: now,
        calendar: calendar
      )
    )
    let components = calendar.dateComponents([.day, .hour], from: cue)

    #expect(components.day == 30)
    #expect(components.hour == 4)
  }

  @Test
  func nightCueUsesCalendarAcrossDaylightSavingBoundary() throws {
    var settings = CueSettings.defaultValue
    settings.bedtimeMinutes = 23 * 60
    settings.nightCueDelayHours = 5
    let now = try #require(
      calendar.date(
        from: DateComponents(year: 2026, month: 10, day: 31, hour: 18)
      )
    )
    let cue = try #require(
      DateCalculator.nextNightCueDate(
        settings: settings,
        now: now,
        calendar: calendar
      )
    )
    let components = calendar.dateComponents([.month, .day, .hour], from: cue)

    #expect(components.month == 11)
    #expect(components.day == 1)
    #expect(components.hour == 3)
  }
}
