import SwiftData
import SwiftUI

struct HomeView: View {
  @Environment(AppModel.self) private var appModel
  @Query private var dreams: [DreamEntry]

  private var insights: JournalInsights {
    JournalInsights(entries: dreams)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        InsightsCard(insights: insights)

        VStack(alignment: .leading) {
          Text("Today’s cue")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          Text(appModel.settings.cueWord)
            .font(.largeTitle)
            .bold()
        }

        Button(
          "Perform Reality Check",
          systemImage: "hand.raised",
          action: didTapRealityCheckButton
        )
        .lucidPrimaryButton()
        .controlSize(.large)
        .frame(maxWidth: .infinity)

        Button(
          "Record a Dream",
          systemImage: "square.and.pencil",
          action: appModel.beginDreamEntry
        )
        .buttonStyle(.bordered)
        .controlSize(.large)
        .frame(maxWidth: .infinity)

        if appModel.purchaseManager.isPro {
          Button("Start WBTB + MILD", systemImage: "moon.zzz") {
            appModel.route = .wbtb
          }
          .buttonStyle(.bordered)
          .controlSize(.large)
          .frame(maxWidth: .infinity)
        }

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
    .lucidScreenBackground()
    .navigationTitle("Lucid Cue")
  }

  private func didTapRealityCheckButton() {
    appModel.route = .realityCheck(source: .iPhoneManual)
  }
}
