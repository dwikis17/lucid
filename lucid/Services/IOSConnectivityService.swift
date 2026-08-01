import Foundation
import WatchConnectivity

@MainActor
final class IOSConnectivityService: NSObject {
  var receivedEvent: ((RealityCheckEvent) -> Void)?

  private let session: WCSession?

  override init() {
    session = WCSession.isSupported() ? .default : nil
    super.init()
  }

  func activate() {
    session?.delegate = self
    session?.activate()
  }

  func send(settings: CueSettings) throws {
    guard let session else {
      throw ConnectivityError.unavailable
    }
    let payload = ConnectivityPayload(settings: settings, updatedAt: .now)
    let data = try JSONEncoder().encode(payload)
    try session.updateApplicationContext(["payload": data])
  }

}

extension IOSConnectivityService: WCSessionDelegate {
  nonisolated func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: (any Error)?
  ) {}

  nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

  nonisolated func sessionDidDeactivate(_ session: WCSession) {
    session.activate()
  }

  nonisolated func session(
    _ session: WCSession,
    didReceiveUserInfo userInfo: [String: Any] = [:]
  ) {
    guard
      let data = userInfo["event"] as? Data,
      let event = try? JSONDecoder().decode(RealityCheckEvent.self, from: data)
    else {
      return
    }
    Task { @MainActor in
      receivedEvent?(event)
    }
  }
}

enum ConnectivityError: LocalizedError {
  case unavailable

  var errorDescription: String? {
    "Watch connectivity is unavailable on this device."
  }
}
