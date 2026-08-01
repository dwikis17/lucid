import Foundation
import Observation

@MainActor
@Observable
final class SettingsRepository {
  private(set) var settings: CueSettings
  private(set) var isWBTBAlarmEnabled: Bool

  private let defaults: UserDefaults
  private let key = "cueSettings"
  private let wbtbAlarmKey = "wbtbAlarmEnabled"

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
    isWBTBAlarmEnabled = defaults.bool(forKey: wbtbAlarmKey)
  }

  func save(_ newSettings: CueSettings, isWBTBAlarmEnabled: Bool? = nil) throws {
    let normalized = CueSettingsValidator.normalized(newSettings)
    let data = try JSONEncoder().encode(normalized)
    defaults.set(data, forKey: key)
    if let isWBTBAlarmEnabled {
      defaults.set(isWBTBAlarmEnabled, forKey: wbtbAlarmKey)
    }
    settings = normalized
    self.isWBTBAlarmEnabled = defaults.bool(forKey: wbtbAlarmKey)
  }
}
