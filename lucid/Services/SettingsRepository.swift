import Foundation
import Observation

@MainActor
@Observable
final class SettingsRepository {
  private(set) var settings: CueSettings

  private let defaults: UserDefaults
  private let key = "cueSettings"

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    if
      let data = defaults.data(forKey: key),
      let decoded = try? JSONDecoder().decode(CueSettings.self, from: data)
    {
      settings = decoded
    } else {
      settings = .defaultValue
    }
  }

  func save(_ newSettings: CueSettings) throws {
    let normalized = CueSettingsValidator.normalized(newSettings)
    let data = try JSONEncoder().encode(normalized)
    defaults.set(data, forKey: key)
    settings = normalized
  }
}
