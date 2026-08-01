import Foundation
import WatchConnectivity

@MainActor
final class WatchConnectivityService: NSObject {
  var receivedPayload: ((ConnectivityPayload) -> Void)?

  private let session: WCSession?

  override init() {
    session = WCSession.isSupported() ? .default : nil
    super.init()
  }

  func activate() {
    session?.delegate = self
    session?.activate()
  }

  func send(event: RealityCheckEvent) throws {
    guard let session else { throw WatchConnectivityError.unavailable }
    let data = try JSONEncoder().encode(event)
    session.transferUserInfo(["event": data])
  }

}

extension WatchConnectivityService: WCSessionDelegate {
  nonisolated func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: (any Error)?
  ) {
    decodePayload(from: session.receivedApplicationContext)
  }

  nonisolated func session(
    _ session: WCSession,
    didReceiveApplicationContext applicationContext: [String: Any]
  ) {
    decodePayload(from: applicationContext)
  }

  nonisolated private func decodePayload(from context: [String: Any]) {
    guard
      let data = context["payload"] as? Data,
      let payload = try? JSONDecoder().decode(ConnectivityPayload.self, from: data)
    else {
      return
    }
    Task { @MainActor in
      receivedPayload?(payload)
    }
  }
}

enum WatchConnectivityError: LocalizedError {
  case unavailable

  var errorDescription: String? {
    "The iPhone connection is unavailable. This check remains saved on Apple Watch."
  }
}
