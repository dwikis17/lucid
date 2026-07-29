import Foundation

enum CueHaptic: String, Codable, CaseIterable, Identifiable, Sendable {
  case notification
  case directionUp
  case directionDown
  case success
  case click

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .notification:
      "Notification"
    case .directionUp:
      "Rising"
    case .directionDown:
      "Falling"
    case .success:
      "Success"
    case .click:
      "Click"
    }
  }
}
