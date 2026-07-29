import Foundation
import Observation
import WatchConnectivity

@MainActor
@Observable
final class IOSConnectivityService: NSObject {
  private(set) var activationState = WCSessionActivationState.notActivated
  private(set) var isWatchPaired = false
  private(set) var isWatchAppInstalled = false
  private(set) var isReachable = false
  var receivedEvent: ((RealityCheckEvent) -> Void)?

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

  func send(settings: CueSettings) throws {
    guard let session else {
      throw ConnectivityError.unavailable
    }
    let payload = ConnectivityPayload(settings: settings, updatedAt: .now)
    let data = try JSONEncoder().encode(payload)
    try session.updateApplicationContext(["payload": data])
  }

  func sendTestCue() throws {
    guard let session else {
      throw ConnectivityError.unavailable
    }
    guard session.isPaired else {
      throw ConnectivityError.watchNotPaired
    }
    guard session.isWatchAppInstalled else {
      throw ConnectivityError.watchAppNotInstalled
    }
    guard session.isReachable else {
      throw ConnectivityError.watchNotReachable
    }
    session.sendMessage(["command": "playTestCue"], replyHandler: nil)
  }

  private func refreshState() {
    guard let session else { return }
    activationState = session.activationState
    isWatchPaired = session.isPaired
    isWatchAppInstalled = session.isWatchAppInstalled
    isReachable = session.isReachable
  }
}

extension IOSConnectivityService: WCSessionDelegate {
  nonisolated func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: (any Error)?
  ) {
    Task { @MainActor in
      refreshState()
    }
  }

  nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
    Task { @MainActor in
      refreshState()
    }
  }

  nonisolated func sessionDidDeactivate(_ session: WCSession) {
    session.activate()
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
  case watchNotPaired
  case watchAppNotInstalled
  case watchNotReachable

  var errorDescription: String? {
    switch self {
    case .unavailable:
      "Watch connectivity is unavailable on this device."
    case .watchNotPaired:
      "No Apple Watch is paired."
    case .watchAppNotInstalled:
      "Install Lucid Cue on your Apple Watch first."
    case .watchNotReachable:
      "Your settings are saved. They will sync to Apple Watch when it becomes available."
    }
  }
}
