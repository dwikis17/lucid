import SwiftData
import SwiftUI

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
    Calendar.current.date(byAdding: .day, value: -selectedDays, to: .now) ?? .distantPast
  }
}
