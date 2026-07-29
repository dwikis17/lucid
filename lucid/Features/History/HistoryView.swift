import SwiftData
import SwiftUI

struct HistoryView: View {
  @Query(sort: \StoredRealityCheckEvent.timestamp, order: .reverse)
  private var events: [StoredRealityCheckEvent]

  private var todayCount: Int {
    events.filter {
      Calendar.current.isDateInToday($0.timestamp) && $0.result == .completed
    }.count
  }

  private var sevenDayEvents: [StoredRealityCheckEvent] {
    guard
      let start = Calendar.current.date(byAdding: .day, value: -7, to: .now)
    else {
      return []
    }
    return events.filter { $0.timestamp >= start }
  }

  private var completionRate: Double {
    guard !sevenDayEvents.isEmpty else { return 0 }
    let completed = sevenDayEvents.filter { $0.result == .completed }.count
    return Double(completed) / Double(sevenDayEvents.count)
  }

  var body: some View {
    Group {
      if events.isEmpty {
        ContentUnavailableView(
          "No recorded checks",
          systemImage: "clock.arrow.circlepath",
          description: Text("Completed and skipped reality checks will appear here.")
        )
      } else {
        List {
          Section("Recorded checks") {
            LabeledContent("Completed today", value: todayCount.formatted())
            LabeledContent(
              "Seven-day completion",
              value: completionRate.formatted(.percent.precision(.fractionLength(0)))
            )
            ProgressView(value: completionRate)
              .accessibilityLabel("Seven-day recorded check completion")
          }

          Section("Recent") {
            ForEach(events) { event in
              HistoryRow(event: event)
            }
          }
        }
      }
    }
    .navigationTitle("History")
  }
}
