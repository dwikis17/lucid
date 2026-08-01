import RevenueCat

enum RevenueCatConfiguration {
  // RevenueCat client keys are safe to bundle in the app. Replace this test key with the
  // production public key before shipping to the App Store.
  static let apiKey = "test_fIblcUHSJxlIVUIQHJBAUPBWhbp"

  static func configure() {
    #if DEBUG
      Purchases.logLevel = .debug
    #endif
    Purchases.configure(withAPIKey: apiKey)
  }
}
