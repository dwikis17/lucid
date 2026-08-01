import Foundation

enum LucidityLevel: Int, CaseIterable, Codable, Sendable {
  case unaware = 0
  case suspicious = 1
  case brief = 2
  case clear = 3
  case sustained = 4
  case throughout = 5

  var title: String {
    switch self {
    case .unaware:
      "Not aware"
    case .suspicious:
      "Vague suspicion"
    case .brief:
      "Brief awareness"
    case .clear:
      "Clearly aware"
    case .sustained:
      "Sustained awareness"
    case .throughout:
      "Aware throughout"
    }
  }

  var symbol: String {
    switch self {
    case .unaware:
      "moon"
    case .suspicious:
      "moon.haze"
    case .brief:
      "moon.stars"
    case .clear:
      "moon.stars.fill"
    case .sustained:
      "sparkles"
    case .throughout:
      "sun.max.fill"
    }
  }

  var isLucid: Bool { rawValue >= LucidityLevel.brief.rawValue }
}
