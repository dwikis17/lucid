import SwiftUI

struct JournalInsights: Equatable {
  let daysStreak: Int
  let entriesThisYear: Int
  let daysJournaled: Int

  init(entries: [DreamEntry], now: Date = .now, calendar: Calendar = .current) {
    let savedEntries = entries.filter { !$0.isDraft }
    let journalDays = Set(savedEntries.map { calendar.startOfDay(for: $0.dreamDate) })

    entriesThisYear = savedEntries.filter {
      calendar.isDate($0.dreamDate, equalTo: now, toGranularity: .year)
    }.count
    daysJournaled = journalDays.count
    daysStreak = Self.streak(from: journalDays, now: now, calendar: calendar)
  }

  private static func streak(
    from journalDays: Set<Date>,
    now: Date,
    calendar: Calendar
  ) -> Int {
    let today = calendar.startOfDay(for: now)
    let startDate: Date?

    if journalDays.contains(today) {
      startDate = today
    } else {
      startDate = calendar.date(byAdding: .day, value: -1, to: today)
        .flatMap { journalDays.contains($0) ? $0 : nil }
    }

    guard var date = startDate else { return 0 }

    var count = 0
    while journalDays.contains(date) {
      count += 1
      guard let previousDate = calendar.date(byAdding: .day, value: -1, to: date) else {
        break
      }
      date = previousDate
    }
    return count
  }
}

struct InsightsCard: View {
  let insights: JournalInsights

  var body: some View {
    GeometryReader { proxy in
      let scale = min(proxy.size.width / 1_080, 1)

      VStack(alignment: .leading, spacing: 22 * scale) {
        Text("Insights")
          .font(.system(size: 50 * scale, weight: .regular, design: .default))
          .foregroundStyle(.white)

        HStack(alignment: .center, spacing: 28 * scale) {
          VStack(alignment: .leading, spacing: 2 * scale) {
            Text(insights.daysStreak.formatted())
              .font(.system(size: 176 * scale, weight: .bold, design: .default))
              .foregroundStyle(.white)
              .minimumScaleFactor(0.7)

            (
              Text("Days ")
                .foregroundStyle(InsightsCardPalette.highlight)
              + Text("Streak")
                .foregroundStyle(InsightsCardPalette.muted)
            )
            .font(.system(size: 38 * scale, weight: .regular, design: .default))
            .lineLimit(1)
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          VStack(alignment: .leading, spacing: 18 * scale) {
            InsightMetricRow(
              symbol: "shippingbox.fill",
              value: insights.entriesThisYear,
              title: "Entries This Year",
              scale: scale
            )
            InsightMetricRow(
              symbol: "calendar",
              value: insights.daysJournaled,
              title: "Days Journaled",
              scale: scale
            )
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .padding(.horizontal, 37 * scale)
      .padding(.vertical, 26 * scale)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .background {
        RoundedRectangle(cornerRadius: 55 * scale, style: .continuous)
          .fill(
            LinearGradient(
              colors: [InsightsCardPalette.top, InsightsCardPalette.bottom],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Insights")
      .accessibilityValue(
        "\(insights.daysStreak) day streak, " +
          "\(insights.entriesThisYear) entries this year, " +
          "\(insights.daysJournaled) days journaled"
      )
    }
    .aspectRatio(1_080 / 408, contentMode: .fit)
  }
}

private struct InsightMetricRow: View {
  let symbol: String
  let value: Int
  let title: String
  let scale: CGFloat

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 14) {
        Image(systemName: symbol)
          .font(.system(size: 42 * scale, weight: .semibold))
          .foregroundStyle(.white)
          .frame(width: 42 * scale)

        Text(value.formatted())
          .font(.system(size: 52 * scale, weight: .regular, design: .default))
          .foregroundStyle(.white)
          .minimumScaleFactor(0.7)
      }

      Text(title)
        .font(.system(size: 38 * scale, weight: .regular, design: .default))
        .foregroundStyle(InsightsCardPalette.muted)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
  }
}

private enum InsightsCardPalette {
  static let top = Color(red: 0.22, green: 0.20, blue: 0.48)
  static let bottom = Color(red: 0.42, green: 0.27, blue: 0.48)
  static let muted = Color(red: 0.71, green: 0.61, blue: 0.79)
  static let highlight = Color(red: 0.95, green: 0.76, blue: 1.0)
}
