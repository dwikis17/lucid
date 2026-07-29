import SwiftData
import SwiftUI

struct HomeView: View {
  @Environment(AppModel.self) private var appModel
  @Query private var events: [StoredRealityCheckEvent]

  private var todayCompletedCount: Int {
    events.filter {
      Calendar.current.isDateInToday($0.timestamp) && $0.result == .completed
    }.count
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading) {
          Text("Today’s cue")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          Text(appModel.settings.cueWord)
            .font(.largeTitle)
            .bold()
        }

        DashboardMetricCard(
          title: "Next daytime reminder",
          value: appModel.nextDaytimeReminder?.formatted(date: .abbreviated, time: .shortened)
            ?? "Not scheduled",
          symbol: "sun.max"
        )
        DashboardMetricCard(
          title: "Next nighttime cue",
          value: appModel.nextNightCue?.formatted(date: .abbreviated, time: .shortened)
            ?? "Disabled",
          symbol: "moon.stars"
        )
        DashboardMetricCard(
          title: "Reality checks today",
          value: todayCompletedCount.formatted(),
          symbol: "checkmark.circle"
        )

        Button(
          "Perform Reality Check",
          systemImage: "hand.raised",
          action: didTapRealityCheckButton
        )
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)

        Button(
          "Test Watch Cue",
          systemImage: "applewatch",
          action: appModel.testWatchCue
        )
        .buttonStyle(.bordered)
        .controlSize(.large)
        .frame(maxWidth: .infinity)

        Button(
          "Reschedule Reminders",
          systemImage: "arrow.clockwise",
          action: didTapRescheduleButton
        )
        .buttonStyle(.bordered)
        .controlSize(.large)
        .frame(maxWidth: .infinity)

        if let message = appModel.statusMessage {
          StatusMessageView(message: message, dismiss: appModel.dismissStatus)
        }

        Text(
          "Lucid Cue is a habit-training and wellness application. Results vary, and " +
            "the app is not a medical or sleep-treatment product."
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
      }
      .padding()
    }
    .navigationTitle("Lucid Cue")
  }

  private func didTapRealityCheckButton() {
    appModel.route = .realityCheck(source: .iPhoneManual)
  }

  private func didTapRescheduleButton() {
    Task {
      await appModel.rescheduleReminders()
    }
  }
}
