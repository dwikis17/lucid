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

        HStack(spacing: 12) {
          Button(action: didTapRealityCheckButton) {
            Label("Reality Check", systemImage: "hand.raised")
              .lineLimit(1)
              .minimumScaleFactor(0.8)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          }
          .lucidPrimaryButton()
          .buttonBorderShape(.roundedRectangle(radius: 16))
          .controlSize(.large)
          .accessibilityLabel("Perform Reality Check")
       

          Button(action: appModel.beginDreamEntry) {
            Label("Record Dream", systemImage: "square.and.pencil")
              .lineLimit(1)
              .minimumScaleFactor(0.8)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          }
          .buttonStyle(.bordered)
          .buttonBorderShape(.roundedRectangle(radius: 16))
          .controlSize(.large)
          .accessibilityLabel("Record a Dream")

        }

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

    .navigationTitle("Home")
  }

  private func didTapRealityCheckButton() {
    appModel.route = .realityCheck(source: .iPhoneManual)
  }
}
