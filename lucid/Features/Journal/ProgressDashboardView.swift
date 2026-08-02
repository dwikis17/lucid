import Charts
import SwiftData
import SwiftUI

struct ProgressTrendPoint: Identifiable, Equatable {
  let date: Date
  let completedChecks: Int
  let lucidDreams: Int

  var id: Date { date }
}

enum ProgressTrend {
  static func makePoints(
    startDate: Date,
    endDate: Date,
    checks: [StoredRealityCheckEvent],
    dreams: [DreamEntry],
    calendar: Calendar = .current
  ) -> [ProgressTrendPoint] {
    let firstDay = calendar.startOfDay(for: startDate)
    let lastDay = calendar.startOfDay(for: endDate)
    guard firstDay <= lastDay else { return [] }

    let completedChecksByDay = Dictionary(
      grouping: checks.filter { $0.result == .completed },
      by: { calendar.startOfDay(for: $0.timestamp) }
    ).mapValues(\.count)
    let lucidDreamsByDay = Dictionary(
      grouping: dreams.filter { !$0.isDraft && $0.lucidity.isLucid },
      by: { calendar.startOfDay(for: $0.dreamDate) }
    ).mapValues(\.count)

    var points: [ProgressTrendPoint] = []
    var day = firstDay
    while day <= lastDay {
      points.append(ProgressTrendPoint(
        date: day,
        completedChecks: completedChecksByDay[day, default: 0],
        lucidDreams: lucidDreamsByDay[day, default: 0]
      ))

      guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
      day = nextDay
    }
    return points
  }
}

struct ProgressDashboardView: View {
  @Environment(AppModel.self) private var appModel
  @Query private var dreams: [DreamEntry]
  @Query private var checks: [StoredRealityCheckEvent]
  @Query private var wbtbSessions: [StoredWBTBSession]
  @State private var selectedDays = 7

  private var recentDreams: [DreamEntry] {
    dreams.filter { !$0.isDraft && $0.dreamDate >= startDate }
  }

  private var recentChecks: [StoredRealityCheckEvent] {
    checks.filter { $0.timestamp >= startDate }
  }

  private var completionRate: Double {
    guard !recentChecks.isEmpty else { return 0 }
    return Double(recentChecks.filter { $0.result == .completed }.count) /
      Double(recentChecks.count)
  }

  private var trendPoints: [ProgressTrendPoint] {
    ProgressTrend.makePoints(
      startDate: startDate,
      endDate: .now,
      checks: recentChecks,
      dreams: recentDreams
    )
  }

  private var trendAccessibilitySummary: String {
    let completedChecks = trendPoints.reduce(0) { $0 + $1.completedChecks }
    let lucidDreams = trendPoints.reduce(0) { $0 + $1.lucidDreams }
    return "\(completedChecks) completed reality checks and " +
      "\(lucidDreams) lucid dreams in the last \(selectedDays) days."
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Last \(selectedDays) days")
          .font(.title2)
          .bold()

        Picker("Time range", selection: $selectedDays) {
          Text("7 days").tag(7)
          if appModel.purchaseManager.isPro {
            Text("30 days").tag(30)
            Text("90 days").tag(90)
          }
        }
        .pickerStyle(.segmented)

        LazyVGrid(
          columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
          ],
          spacing: 12
        ) {
          DashboardMetricCard(
            title: "Dreams recorded",
            value: recentDreams.count.formatted(),
            symbol: "moon.stars"
          )
          DashboardMetricCard(
            title: "Lucid dreams",
            value: recentDreams.filter { $0.lucidity.isLucid }.count.formatted(),
            symbol: "sparkles"
          )
          DashboardMetricCard(
            title: "Reality-check completion",
            value: completionRate.formatted(.percent.precision(.fractionLength(0))),
            symbol: "checkmark.circle"
          )
          DashboardMetricCard(
            title: "WBTB sessions",
            value: wbtbSessions.filter { $0.completedAt >= startDate }.count.formatted(),
            symbol: "moon.zzz"
          )
        }

        practiceTrendCard

        Text(
          "These are observations from your journal and practice history, not a promise " +
            "that any technique will cause a lucid dream."
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
      }
      .padding()
    }
    .lucidScreenBackground()
    .navigationTitle("Progress")
  }

  private var startDate: Date {
    let today = Calendar.current.startOfDay(for: .now)
    return Calendar.current.date(
      byAdding: .day,
      value: -(selectedDays - 1),
      to: today
    ) ?? .distantPast
  }

  private var practiceTrendCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Practice trend")
        .font(.headline)

      if trendPoints.allSatisfy({ $0.completedChecks == 0 && $0.lucidDreams == 0 }) {
        Label("No activity yet", systemImage: "chart.bar.xaxis")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, minHeight: 120)
      } else {
        Chart {
          ForEach(trendPoints) { point in
            BarMark(
              x: .value("Day", point.date, unit: .day),
              y: .value("Count", point.completedChecks)
            )
            .foregroundStyle(by: .value("Activity", "Reality checks"))

            BarMark(
              x: .value("Day", point.date, unit: .day),
              y: .value("Count", point.lucidDreams)
            )
            .foregroundStyle(by: .value("Activity", "Lucid dreams"))
          }
        }
        .chartForegroundStyleScale([
          "Reality checks": LucidTheme.moonmint,
          "Lucid dreams": LucidTheme.lucidIndigo
        ])
        .chartLegend(position: .bottom, alignment: .leading)
        .chartXAxis {
          if selectedDays <= 7 {
            AxisMarks(values: .stride(by: .day)) { _ in
              AxisGridLine()
              AxisTick()
              AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
          } else {
            AxisMarks(values: .stride(by: .weekOfYear)) { _ in
              AxisGridLine()
              AxisTick()
              AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
          }
        }
        .frame(height: 220)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Practice trend")
        .accessibilityValue(trendAccessibilitySummary)
      }
    }
    .lucidCard()
  }
}
