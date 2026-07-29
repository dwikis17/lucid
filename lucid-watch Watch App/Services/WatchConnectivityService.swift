import Foundation
import Observation
import WatchConnectivity

@MainActor
@Observable
final class WatchConnectivityService: NSObject {
  private(set) var activationState = WCSessionActivationState.notActivated
  private(set) var isReachable = false
  var receivedPayload: ((ConnectivityPayload) -> Void)?
  var didReceiveTestCue: (() -> Void)?

  private let session: WCSession?

  override init() {
    session = WCSession.isSupported() ? .default : nil
    super.init()
  }

  func activate() {
    session?.delegate = self
    session?.activate()
    refreshState()
  }

  func send(event: RealityCheckEvent) throws {
    guard let session else { throw WatchConnectivityError.unavailable }
    let data = try JSONEncoder().encode(event)
    session.transferUserInfo(["event": data])
  }

  private func refreshState() {
    activationState = session?.activationState ?? .notActivated
    isReachable = session?.isReachable ?? false
  }
}

extension WatchConnectivityService: WCSessionDelegate {
  nonisolated func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: (any Error)?
  ) {
    Task { @MainActor in
      refreshState()
    }
  }

  nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
    Task { @MainActor in
      refreshState()
    }
  }

  nonisolated func session(
    _ session: WCSession,
    didReceiveApplicationContext applicationContext: [String: Any]
  ) {
    decodePayload(from: applicationContext)
  }

  nonisolated func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any]
  ) {
    guard message["command"] as? String == "playTestCue" else { return }
    Task { @MainActor in
      didReceiveTestCue?()
    }
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
