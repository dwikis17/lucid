import SwiftUI

struct DashboardMetricCard: View {
  let title: String
  let value: String
  let symbol: String

  var body: some View {
    VStack(alignment: .leading) {
      Label(title, systemImage: symbol)
        .font(.subheadline)
        .foregroundStyle(.secondary)
      Text(value)
        .font(.headline)
        .contentTransition(.numericText())
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .lucidCard()
  }
}
