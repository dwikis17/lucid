import WatchKit

struct WatchHapticService {
  func play(_ haptic: CueHaptic) {
    let type: WKHapticType
    switch haptic {
    case .notification:
      type = .notification
    case .directionUp:
      type = .directionUp
    case .directionDown:
      type = .directionDown
    case .success:
      type = .success
    case .click:
      type = .click
    }
    WKInterfaceDevice.current().play(type)
  }
}
