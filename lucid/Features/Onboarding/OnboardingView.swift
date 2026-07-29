import SwiftUI

struct OnboardingView: View {
  @Environment(AppModel.self) private var appModel
  @Binding var hasCompletedOnboarding: Bool
  @State private var selectedPage = 0

  private let pages = [
    OnboardingPage(
      id: 0,
      symbol: "hand.raised.fingers.spread",
      title: "Build awareness",
      detail: "Reality checks create a small daytime habit: pause, inspect what is around " +
        "you, and ask whether you are dreaming."
    ),
    OnboardingPage(
      id: 1,
      symbol: "bell.badge",
      title: "Notice your cue",
      detail: "Lucid Cue distributes a few gentle reminders through your chosen daytime " +
        "window, always using the same cue word."
    ),
    OnboardingPage(
      id: 2,
      symbol: "applewatch.radiowaves.left.and.right",
      title: "A gentle nighttime cue",
      detail: "Apple Watch schedules one local nighttime notification. Focus modes, device " +
        "settings, and the system control its timing and haptic."
    ),
  ]

  var body: some View {
    VStack {
      TabView(selection: $selectedPage) {
        ForEach(pages) { page in
          OnboardingPageView(page: page)
            .tag(page.id)
        }

        NotificationPermissionView(
          hasCompletedOnboarding: $hasCompletedOnboarding
        )
        .tag(pages.count)
      }
      .tabViewStyle(.page(indexDisplayMode: .always))

      if selectedPage < pages.count {
        Button("Continue", systemImage: "arrow.right", action: didTapContinueButton)
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          .padding()
      }
    }
  }

  private func didTapContinueButton() {
    withAnimation {
      selectedPage += 1
    }
  }
}
