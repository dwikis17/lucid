import SwiftUI

struct OnboardingPageView: View {
  let page: OnboardingPage

  var body: some View {
    VStack(spacing: 24) {
      Image(systemName: page.symbol)
        .symbolRenderingMode(.hierarchical)
        .lucidHeroSymbol()
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

#Preview {
  OnboardingPageView(
    page: OnboardingPage(
      id: 0,
      symbol: "hand.raised.fingers.spread",
      title: "Build awareness",
      detail: "Reality checks create a small daytime habit: pause, inspect what is around " +
        "you, and ask whether you are dreaming."
    )
  )
  .lucidScreenBackground()
  .preferredColorScheme(.dark)
}

