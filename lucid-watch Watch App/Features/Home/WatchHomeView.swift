import SwiftUI

struct WatchHomeView: View {
  @Environment(WatchAppModel.self) private var appModel

  var body: some View {
    ScrollView {
      VStack(spacing: 12) {
        Text(appModel.settings.cueWord)
          .font(.title2)
          .bold()
          .foregroundStyle(.tint)

        Text("Am I dreaming?")
          .font(.headline)

        Button(
          "Reality Check",
          systemImage: "hand.raised",
          action: appModel.showManualRealityCheck
        )
        .lucidPrimaryButton()

        if let nextNightCue = appModel.nextNightCue {
          LabeledContent("Night cue") {
            Text(nextNightCue, format: .dateTime.hour().minute())
          }
          .font(.footnote)
        } else {
          Text("Night cues arrive from iPhone")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }

        if let statusMessage = appModel.statusMessage {
          Text(statusMessage)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
      }
      .padding(.horizontal)
    }
    .lucidScreenBackground()
    .navigationTitle("Lucid Cue")
  }
}
