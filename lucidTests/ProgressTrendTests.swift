import Foundation
import Testing
@testable import lucid

struct ProgressTrendTests {
  private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }

  @Test
  func aggregatesCompletedChecksAndLucidDreamsIntoZeroFilledDays() throws {
    let checks = [
      StoredRealityCheckEvent(event: RealityCheckEvent(
        id: UUID(),
        timestamp: date(day: 1, hour: 9),
        source: .iPhoneManual,
        result: .completed,
        cueWord: "Dream"
      )),
      StoredRealityCheckEvent(event: RealityCheckEvent(
        id: UUID(),
        timestamp: date(day: 1, hour: 10),
        source: .iPhoneManual,
        result: .skipped,
        cueWord: "Dream"
      )),
      StoredRealityCheckEvent(event: RealityCheckEvent(
        id: UUID(),
        timestamp: date(day: 3, hour: 12),
        source: .watchManual,
        result: .completed,
        cueWord: "Dream"
      )),
      StoredRealityCheckEvent(event: RealityCheckEvent(
        id: UUID(),
        timestamp: date(day: 4, hour: 12),
        source: .watchManual,
        result: .completed,
        cueWord: "Dream"
      ))
    ]
    let dreams = [
      DreamEntry(dreamDate: date(day: 1, hour: 7), lucidity: .clear, isDraft: false),
      DreamEntry(dreamDate: date(day: 2, hour: 7), lucidity: .clear, isDraft: true),
      DreamEntry(dreamDate: date(day: 3, hour: 7), lucidity: .unaware, isDraft: false),
      DreamEntry(dreamDate: date(day: 4, hour: 7), lucidity: .clear, isDraft: false)
    ]

    let points = ProgressTrend.makePoints(
      startDate: date(day: 1, hour: 6),
      endDate: date(day: 3, hour: 18),
      checks: checks,
      dreams: dreams,
      calendar: calendar
    )

    #expect(points.map(\.completedChecks) == [1, 0, 1])
    #expect(points.map(\.lucidDreams) == [1, 0, 0])
    #expect(points.map(\.date) == [date(day: 1), date(day: 2), date(day: 3)])
  }

  private func date(day: Int, hour: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 8, day: day, hour: hour))!
  }
}
