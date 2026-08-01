import LocalAuthentication
import Observation

@MainActor
@Observable
final class AppLockManager {
  private(set) var isLocked: Bool
  private(set) var isEnabled: Bool

  private let defaults: UserDefaults
  private let enabledKey = "appLockEnabled"

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    let enabled = defaults.bool(forKey: enabledKey)
    isEnabled = enabled
    isLocked = enabled
  }

  func setEnabled(_ enabled: Bool) {
    isEnabled = enabled
    defaults.set(enabled, forKey: enabledKey)
    if !enabled {
      isLocked = false
    }
  }

  func lockIfNeeded() {
    guard isEnabled else { return }
    isLocked = true
  }

  func unlock() async -> Bool {
    guard isEnabled else {
      isLocked = false
      return true
    }

    let context = LAContext()
    do {
      let unlocked = try await context.evaluatePolicy(
        .deviceOwnerAuthentication,
        localizedReason: "Unlock your dream journal."
      )
      if unlocked {
        isLocked = false
      }
      return unlocked
    } catch {
      return false
    }
  }
}
