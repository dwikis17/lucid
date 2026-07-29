import SwiftUI

struct OnboardingPageView: View {
  let page: OnboardingPage

  var body: some View {
    VStack(spacing: 24) {
      Image(systemName: page.symbol)
        .font(.largeTitle)
        .foregroundStyle(.tint)
        .accessibilityHidden(true)

      Text(page.title)
        .font(.title)
        .bold()
        .multilineTextAlignment(.center)

      Text(page.detail)
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
  }
}
