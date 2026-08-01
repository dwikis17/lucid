import SwiftUI

enum LucidTheme {
  static let deepTwilight = Color(red: 21 / 255, green: 27 / 255, blue: 61 / 255)
  static let lucidIndigo = Color(red: 77 / 255, green: 85 / 255, blue: 165 / 255)
  static let moonmint = Color(red: 169 / 255, green: 244 / 255, blue: 208 / 255)
  static let moonlight = Color(red: 244 / 255, green: 241 / 255, blue: 213 / 255)
  static let coolMist = Color(red: 238 / 255, green: 241 / 255, blue: 247 / 255)

  static let background = LinearGradient(
    colors: [deepTwilight, lucidIndigo.opacity(0.55), deepTwilight],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )
}

extension View {
  func lucidScreenBackground() -> some View {
    background {
      ZStack {
        LucidTheme.deepTwilight
        LucidTheme.background
      }
      .ignoresSafeArea()
    }
  }

  func lucidCard(cornerRadius: CGFloat = 16) -> some View {
    padding()
      .background(.regularMaterial)
      .overlay {
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(.tint.opacity(0.18))
      }
      .clipShape(.rect(cornerRadius: cornerRadius))
  }

  func lucidPrimaryButton() -> some View {
    buttonStyle(.borderedProminent)
      .tint(LucidTheme.moonmint)
      .foregroundStyle(LucidTheme.deepTwilight)
  }

  func lucidHeroSymbol() -> some View {
    font(.system(size: 40, weight: .semibold))
      .foregroundStyle(.tint)
      .frame(width: 80, height: 80)
      .background(LucidTheme.moonmint.opacity(0.14))
      .clipShape(.circle)
  }
}
