import Foundation
import Observation

@MainActor
@Observable
final class WatchSettingsRepository {
  private(set) var payload: ConnectivityPayload

  private let defaults: UserDefaults
  private let key = "watchCueSettingsPayload"

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    if
      let data = defaults.data(forKey: key),
      let decoded = try? JSONDecoder().decode(ConnectivityPayload.self, from: data)
    {
      payload = decoded
    } else {
      payload = ConnectivityPayload(settings: .defaultValue, updatedAt: .distantPast)
    }
  }

  @discardableResult
  func saveIfNewer(_ newPayload: ConnectivityPayload) throws -> Bool {
    guard newPayload.updatedAt > payload.updatedAt else { return false }
    let data = try JSONEncoder().encode(newPayload)
    defaults.set(data, forKey: key)
    payload = newPayload
    return true
  }
}
