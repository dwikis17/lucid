import SwiftUI

struct HistoryRow: View {
  let event: StoredRealityCheckEvent

  var body: some View {
    Label {
      VStack(alignment: .leading) {
        Text(event.result == .completed ? "Checked" : "Skipped")
          .font(.headline)
        Text("\(event.source.displayName) · \(event.cueWord)")
          .font(.subheadline)
          .foregroundStyle(.secondary)
        Text(event.timestamp, format: .dateTime.weekday().month().day().hour().minute())
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    } icon: {
      Image(systemName: event.result == .completed ? "checkmark.circle.fill" : "forward.circle")
        .foregroundStyle(event.result == .completed ? .green : .secondary)
    }
  }
}
