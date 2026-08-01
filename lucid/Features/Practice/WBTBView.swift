import SwiftData
import SwiftUI

struct WBTBView: View {
  @Environment(AppModel.self) private var appModel
  @Environment(\.dismiss) private var dismiss
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Query(sort: \DreamEntry.dreamDate, order: .reverse)
  private var dreams: [DreamEntry]
  @State private var step = 0
  @State private var remainingSeconds = 0

  private var latestDream: DreamEntry? {
    dreams.first(where: { !$0.isDraft && $0.hasContent })
  }

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 20) {
        Text(title)
          .font(.largeTitle)
          .bold()

        Text(detail)
          .foregroundStyle(.secondary)

        if step == 0, let latestDream {
          VStack(alignment: .leading, spacing: 8) {
            Label("Recall this dream", systemImage: "moon.stars")
              .font(.headline)
            Text(latestDream.displayTitle)
              .font(.title3)
            Text(latestDream.previewText)
              .foregroundStyle(.secondary)
              .lineLimit(5)
          }
          .lucidCard()
        }

        Spacer()

        if step == 1 {
          Text(timeRemaining)
            .font(.system(.title, design: .rounded).monospacedDigit())
            .frame(maxWidth: .infinity)
            .accessibilityLabel("\(remainingSeconds) seconds remaining")
        }

        Button(step == 1 ? "Return to Bed" : "Continue", systemImage: "moon.zzz") {
          advance()
        }
        .lucidPrimaryButton()
        .controlSize(.large)
        .frame(maxWidth: .infinity)
      }
      .padding()
      .lucidScreenBackground()
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close", systemImage: "xmark", action: dismiss.callAsFunction)
        }
      }
      .task(id: step) { await runTimerIfNeeded() }
    }
  }

  private var title: String {
    switch step {
    case 0: "Wake gently"
    case 1: "Set your intention"
    default: "Ready for sleep"
    }
  }

  private var detail: String {
    switch step {
    case 0:
      "Remember a recent dream and notice one detail that would feel unusual if it happened again."
    case 1:
      "Imagine noticing that detail in a dream. Repeat: next time I’m dreaming, I’ll remember I’m dreaming."
    default:
      "Let the thought go and return to sleep. Lucid Cue does not guarantee a wake-up or a lucid dream."
    }
  }

  private var timeRemaining: String {
    let minutes = remainingSeconds / 60
    let seconds = remainingSeconds % 60
    let minuteText = minutes < 10 ? "0\(minutes)" : "\(minutes)"
    let secondText = seconds < 10 ? "0\(seconds)" : "\(seconds)"
    return "\(minuteText):\(secondText)"
  }

  private func advance() {
    if step == 1 {
      appModel.recordWBTBSession()
      dismiss()
      return
    }
    withAnimation(reduceMotion ? nil : .easeInOut) {
      step += 1
      remainingSeconds = appModel.settings.wbtbRoutineMinutes * 60
    }
  }

  private func runTimerIfNeeded() async {
    guard step == 1 else { return }
    while remainingSeconds > 0 {
      do {
        try await Task.sleep(for: .seconds(1))
      } catch {
        return
      }
      remainingSeconds -= 1
    }
  }
}
