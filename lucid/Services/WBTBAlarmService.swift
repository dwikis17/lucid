import AlarmKit
import AppIntents
import ActivityKit
import Foundation
import SwiftUI

enum WBTBAlarmError: LocalizedError {
  case authorizationDenied

  var errorDescription: String? {
    switch self {
    case .authorizationDenied:
      "Alarm permission is off. Enable alarms in Settings to use WBTB Alarm mode."
    }
  }
}

enum WBTBAlarmService {
  static let openWBTBKey = "lucid.openWBTBFromAlarm"

  private static let alarmID = UUID(uuidString: "9D2EA5A7-4D90-4F6A-A1C9-7C8E6E5D4B31") ?? UUID()

  @available(iOS 26.0, *)
  static func reconcile(settings: CueSettings) async throws {
    cancel()

    guard
      settings.isEnabled,
      settings.isNightCueEnabled,
      settings.hasAcknowledgedWBTBSafety,
      !settings.wbtbWeekdays.isEmpty
    else { return }

    let authorization: AlarmManager.AuthorizationState
    if AlarmManager.shared.authorizationState == .notDetermined {
      authorization = try await AlarmManager.shared.requestAuthorization()
    } else {
      authorization = AlarmManager.shared.authorizationState
    }
    guard authorization == .authorized else {
      throw WBTBAlarmError.authorizationDenied
    }

    let weekdays = settings.wbtbWeekdays.compactMap(weekday(for:))
    guard !weekdays.isEmpty else { return }

    let minutes = DateCalculator.nightCueMinutes(settings: settings)
    let schedule = Alarm.Schedule.relative(
      .init(
        time: .init(hour: minutes / 60, minute: minutes % 60),
        repeats: .weekly(weekdays)
      )
    )
    let stopButton = AlarmButton(
      text: "Open Lucid",
      textColor: .white,
      systemImageName: "moon.stars"
    )
    let snoozeButton = AlarmButton(
      text: "Snooze 5 minutes",
      textColor: .white,
      systemImageName: "zzz"
    )
    let presentation = AlarmPresentation(
      alert: .init(
        title: "Wake Back to Bed",
        stopButton: stopButton,
        secondaryButton: snoozeButton,
        secondaryButtonBehavior: .countdown
      )
    )
    let attributes = AlarmAttributes<Metadata>(presentation: presentation, tintColor: .indigo)
    let configuration = AlarmManager.AlarmConfiguration(
      countdownDuration: .init(preAlert: nil, postAlert: 5 * 60),
      schedule: schedule,
      attributes: attributes,
      stopIntent: OpenWBTBIntent(),
      sound: .default
    )

    _ = try await AlarmManager.shared.schedule(id: alarmID, configuration: configuration)
  }

  static func cancel() {
    if #available(iOS 26.0, *) {
      try? AlarmManager.shared.cancel(id: alarmID)
    }
  }

  @available(iOS 26.0, *)
  private static func weekday(for value: Int) -> Locale.Weekday? {
    switch value {
    case 1: .sunday
    case 2: .monday
    case 3: .tuesday
    case 4: .wednesday
    case 5: .thursday
    case 6: .friday
    case 7: .saturday
    default: nil
    }
  }

  @available(iOS 26.0, *)
  private struct Metadata: AlarmMetadata {}

  private struct OpenWBTBIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Open WBTB" }
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
      UserDefaults.standard.set(true, forKey: WBTBAlarmService.openWBTBKey)
      return .result()
    }
  }
}
