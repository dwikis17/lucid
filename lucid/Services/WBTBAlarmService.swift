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
  private static let testAlarmID = UUID(uuidString: "0A4AA1CB-5C8C-45F0-BB6D-8A49EEDB7A9B") ?? UUID()

  @available(iOS 26.0, *)
  static func reconcile(settings: CueSettings) async throws {
    cancel()

    guard
      settings.isEnabled,
      settings.isNightCueEnabled,
      settings.hasAcknowledgedWBTBSafety,
      !settings.wbtbWeekdays.isEmpty
    else { return }

    guard try await isAuthorized() else {
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
    _ = try await AlarmManager.shared.schedule(
      id: alarmID,
      configuration: configuration(for: schedule)
    )
  }

  @available(iOS 26.0, *)
  static func scheduleTestAlarm() async throws {
    cancelTestAlarm()
    guard try await isAuthorized() else {
      throw WBTBAlarmError.authorizationDenied
    }
    _ = try await AlarmManager.shared.schedule(
      id: testAlarmID,
      configuration: configuration(
        for: .fixed(Date.now.addingTimeInterval(10))
      )
    )
  }

  static func cancel() {
    if #available(iOS 26.0, *) {
      try? AlarmManager.shared.cancel(id: alarmID)
    }
  }

  static func cancelTestAlarm() {
    if #available(iOS 26.0, *) {
      try? AlarmManager.shared.cancel(id: testAlarmID)
    }
  }

  @available(iOS 26.0, *)
  private static func isAuthorized() async throws -> Bool {
    if AlarmManager.shared.authorizationState == .notDetermined {
      return try await AlarmManager.shared.requestAuthorization() == .authorized
    }
    return AlarmManager.shared.authorizationState == .authorized
  }

  @available(iOS 26.0, *)
  private static func configuration(
    for schedule: Alarm.Schedule
  ) -> AlarmManager.AlarmConfiguration<Metadata> {
    AlarmManager.AlarmConfiguration(
      countdownDuration: .init(preAlert: nil, postAlert: 5 * 60),
      schedule: schedule,
      attributes: AlarmAttributes<Metadata>(
        presentation: alarmPresentation(),
        tintColor: .indigo
      ),
      stopIntent: OpenWBTBIntent(),
      sound: .default
    )
  }

  @available(iOS 26.0, *)
  private static func alarmPresentation() -> AlarmPresentation {
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
    return AlarmPresentation(
      alert: .init(
        title: "Wake Back to Bed",
        stopButton: stopButton,
        secondaryButton: snoozeButton,
        secondaryButtonBehavior: .countdown
      )
    )
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
