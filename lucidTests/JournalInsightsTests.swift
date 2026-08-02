import Foundation
import Testing
@testable import lucid

struct JournalInsightsTests {
  private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }

  private var now: Date {
    calendar.date(from: DateComponents(year: 2026, month: 8, day: 3, hour: 12))!
  }

  @Test
  func countsSavedEntriesAndUniqueJournalDaysWithinTheCurrentYear() {
    let entries = [
      DreamEntry(dreamDate: date(year: 2026, month: 8, day: 1), isDraft: false),
      DreamEntry(dreamDate: date(year: 2026, month: 8, day: 1), isDraft: false),
      DreamEntry(dreamDate: date(year: 2025, month: 12, day: 31), isDraft: false),
      DreamEntry(dreamDate: date(year: 2026, month: 8, day: 2))
    ]

    let insights = JournalInsights(entries: entries, now: now, calendar: calendar)

    #expect(insights.entriesThisYear == 2)
    #expect(insights.daysJournaled == 2)
  }

  @Test
  func streakEndsToday() {
    let entries = [
      savedEntry(daysAgo: 0),
      savedEntry(daysAgo: 1),
      savedEntry(daysAgo: 2)
    ]

    #expect(JournalInsights(entries: entries, now: now, calendar: calendar).daysStreak == 3)
  }

  @Test
  func streakMayEndYesterday() {
    let entries = [
      savedEntry(daysAgo: 1),
      savedEntry(daysAgo: 2)
    ]

    #expect(JournalInsights(entries: entries, now: now, calendar: calendar).daysStreak == 2)
  }

  @Test
  func streakStopsAtAMissingDay() {
    let entries = [
      savedEntry(daysAgo: 0),
      savedEntry(daysAgo: 2)
    ]

    #expect(JournalInsights(entries: entries, now: now, calendar: calendar).daysStreak == 1)
  }

  @Test
  func emptyJournalReturnsZeroValues() {
    let insights = JournalInsights(entries: [], now: now, calendar: calendar)

    #expect(insights.daysStreak == 0)
    #expect(insights.entriesThisYear == 0)
    #expect(insights.daysJournaled == 0)
  }

  private func date(year: Int, month: Int, day: Int) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
  }

  private func savedEntry(daysAgo: Int) -> DreamEntry {
    let day = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
    return DreamEntry(dreamDate: day, isDraft: false)
  }
}
