import SwiftUI

struct WatchRealityCheckView: View {
  @Environment(WatchAppModel.self) private var appModel
  @Environment(\.dismiss) private var dismiss
  let source: RealityCheckEvent.Source

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        Text("Are you dreaming?")
          .font(.headline)
          .bold()

        Label("Look at your hands", systemImage: "hand.raised")
        Label("Count your fingers", systemImage: "number")
        Label("Read text twice", systemImage: "text.book.closed")
        Label("Notice anything unusual", systemImage: "questionmark.circle")

        Button("I Checked", action: didTapCheckedButton)
          .buttonStyle(.borderedProminent)

        Button("Skip", action: didTapSkipButton)
          .buttonStyle(.bordered)
      }
    }
    .navigationTitle("Reality Check")
  }

  private func didTapCheckedButton() {
    appModel.record(result: .completed, source: source)
    dismiss()
  }

  private func didTapSkipButton() {
    appModel.record(result: .skipped, source: source)
    dismiss()
  }
}
