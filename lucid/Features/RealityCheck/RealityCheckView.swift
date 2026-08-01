import SwiftUI

struct RealityCheckView: View {
  @Environment(AppModel.self) private var appModel
  @Environment(\.dismiss) private var dismiss
  @Environment(\.accessibilityReduceMotion) private var isReduceMotionEnabled
  let source: RealityCheckEvent.Source

  private let steps = [
    "Look at your hands.",
    "Count your fingers.",
    "Read a piece of text twice.",
    "Ask whether anything feels unusual.",
  ]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          Text("Are you dreaming?")
            .font(.largeTitle)
            .bold()

          Text("Pause. Give each step your full attention.")
            .foregroundStyle(.secondary)

          ForEach(steps.indices, id: \.self) { index in
            Label {
              Text(steps[index])
            } icon: {
              Text((index + 1).formatted())
                .bold()
                .frame(minWidth: 32, minHeight: 32)
                .background(.tint.opacity(0.15))
                .clipShape(.circle)
            }
          }

          Button("I Checked", systemImage: "checkmark.circle", action: didTapCheckedButton)
          .lucidPrimaryButton()
          .controlSize(.large)
          .frame(maxWidth: .infinity)

          Button("Skip", action: didTapSkipButton)
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
        }
        .padding()
      }
      .lucidScreenBackground()
      .navigationTitle("Reality Check")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Close", systemImage: "xmark", action: dismiss.callAsFunction)
        }
      }
    }
  }

  private func didTapCheckedButton() {
    appModel.record(result: .completed, source: source)
    if isReduceMotionEnabled {
      dismiss()
    } else {
      withAnimation(.easeOut) {
        dismiss()
      }
    }
  }

  private func didTapSkipButton() {
    appModel.record(result: .skipped, source: source)
    dismiss()
  }
}
