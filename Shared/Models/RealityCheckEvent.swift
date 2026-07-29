import Foundation

struct RealityCheckEvent: Codable, Identifiable, Equatable, Sendable {
  enum Source: String, Codable, CaseIterable, Sendable {
    case iPhoneNotification
    case watchNotification
    case iPhoneManual
    case watchManual

    var displayName: String {
      switch self {
      case .iPhoneNotification:
        "iPhone reminder"
      case .watchNotification:
        "Watch reminder"
      case .iPhoneManual:
        "iPhone"
      case .watchManual:
        "Apple Watch"
      }
    }
  }

  enum Result: String, Codable, Sendable {
    case completed
    case skipped
  }

  let id: UUID
  let timestamp: Date
  let source: Source
  let result: Result
  let cueWord: String
}
