import SwiftUI

struct SetupView: View {
  @Environment(AppModel.self) private var appModel
  @State private var draft = CueSettings.defaultValue
  @State private var daytimeStart = Date.now
  @State private var daytimeEnd = Date.now
  @State private var bedtime = Date.now
  @State private var morningReminder = Date.now
  @State private var isWBTBAlarmEnabled = false
  @State private var isLoaded = false
  @State private var validationErrors: [String] = []
  @State private var isSaving = false
  @State private var didSave = false
  @State private var saveError: String?

  var body: some View {
    Form {
      Section("Cue") {
        TextField("Cue word", text: $draft.cueWord)
          .textInputAutocapitalization(.words)
        Picker("Completion haptic", selection: $draft.selectedHaptic) {
          ForEach(CueHaptic.allCases) { haptic in
            Text(haptic.displayName).tag(haptic)
          }
        }
      }

      Section("Daytime reminders") {
        Picker("Reminders per day", selection: $draft.daytimeReminderCount) {
          ForEach(3...5, id: \.self) { count in
            Text(count.formatted()).tag(count)
          }
        }
        DatePicker("Start", selection: $daytimeStart, displayedComponents: .hourAndMinute)
        DatePicker("End", selection: $daytimeEnd, displayedComponents: .hourAndMinute)
      }

      if appModel.purchaseManager.isPro {
        Section("Nighttime cue") {
          Toggle("WBTB + MILD", isOn: $draft.isNightCueEnabled)
          DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
          Picker("Delay after bedtime", selection: $draft.nightCueDelayHours) {
            ForEach([4, 5, 6], id: \.self) { hours in
              Text("\(hours) hours").tag(hours)
            }
          }
          .disabled(!draft.isNightCueEnabled)
          Toggle("Use as wake-up alarm", isOn: $isWBTBAlarmEnabled)
            .disabled(!draft.isNightCueEnabled)
          Text(
            "Gentle cue is the default. Alarm mode uses the system alarm when available; older " +
              "iOS versions use a time-sensitive notification. Lucid cannot guarantee a wake-up."
          )
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      Section("WBTB nights") {
        Toggle("I understand the WBTB safety notice", isOn: $draft.hasAcknowledgedWBTBSafety)
        Text("WBTB can interrupt sleep. Skip it when you need uninterrupted rest; Lucid cannot guarantee a wake-up.")
          .font(.footnote)
          .foregroundStyle(.secondary)
        ForEach(1...7, id: \.self) { weekday in
            Button {
              toggleWeekday(weekday)
            } label: {
              HStack {
                Text(weekdayName(weekday))
                Spacer()
                if draft.wbtbWeekdays.contains(weekday) {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
                } else {
                  Image(systemName: "circle")
                    .foregroundStyle(.secondary)
                }
              }
            }
            .buttonStyle(.plain)
            .accessibilityValue(draft.wbtbWeekdays.contains(weekday) ? "Selected" : "Not selected")
          }
          Picker("Guided routine", selection: $draft.wbtbRoutineMinutes) {
            Text("5 minutes").tag(5)
            Text("10 minutes").tag(10)
          }
          Text("Choose up to two nights. Skip WBTB when you need uninterrupted sleep.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      } else {
        Section("WBTB + MILD") {
          NavigationLink("Unlock Lucid Cue Pro", value: SettingsDestination.pro)
          Text("Scheduled cues and the guided routine are included with Pro.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }

      Section("Morning journal") {
        Toggle("Morning reminder", isOn: $draft.isMorningReminderEnabled)
        DatePicker(
          "Time",
          selection: $morningReminder,
          displayedComponents: .hourAndMinute
        )
        .disabled(!draft.isMorningReminderEnabled)
      }

      Section("Delivery") {
        Toggle("Reminders enabled", isOn: $draft.isEnabled)
        Toggle("Notification sound", isOn: $draft.isSoundEnabled)
      }

      if !validationErrors.isEmpty {
        Section("Please review") {
          ForEach(validationErrors, id: \.self) { error in
            Label(error, systemImage: "exclamationmark.circle")
              .foregroundStyle(.red)
          }
        }
      }

      if didSave {
        Section {
          Label("Settings saved.", systemImage: "checkmark.circle.fill")
            .foregroundStyle(LucidTheme.moonmint)
        }
      } else if let saveError {
        Section {
          Label(saveError, systemImage: "exclamationmark.circle")
            .foregroundStyle(.red)
        }
      }

      Section {
        Button("Save & Schedule", systemImage: "checkmark", action: didTapSaveButton)
          .disabled(isSaving)
      }
    }
    .scrollContentBackground(.hidden)
    .lucidScreenBackground()
    .onAppear(perform: loadSettings)
    .sensoryFeedback(.success, trigger: didSave) { _, newValue in
      newValue
    }
  }

  private func loadSettings() {
    guard !isLoaded else { return }
    draft = appModel.settings
    isWBTBAlarmEnabled = appModel.isWBTBAlarmEnabled
    daytimeStart = date(for: draft.daytimeStartMinutes)
    daytimeEnd = date(for: draft.daytimeEndMinutes)
    bedtime = date(for: draft.bedtimeMinutes)
    morningReminder = date(for: draft.morningReminderMinutes)
    isLoaded = true
  }

  private func didTapSaveButton() {
    didSave = false
    saveError = nil
    draft.daytimeStartMinutes = minutes(for: daytimeStart)
    draft.daytimeEndMinutes = minutes(for: daytimeEnd)
    draft.bedtimeMinutes = minutes(for: bedtime)
    draft.morningReminderMinutes = minutes(for: morningReminder)
    validationErrors = CueSettingsValidator.errors(for: draft)
    guard validationErrors.isEmpty else { return }

    isSaving = true
    Task {
      let saved = await appModel.save(
        settings: draft,
        isWBTBAlarmEnabled: isWBTBAlarmEnabled
      )
      isSaving = false
      isWBTBAlarmEnabled = appModel.isWBTBAlarmEnabled
      if saved {
        didSave = true
      } else {
        saveError = appModel.statusMessage ?? "Could not save settings."
      }
    }
  }

  private func date(for minutes: Int) -> Date {
    Calendar.current.date(
      byAdding: .minute,
      value: minutes,
      to: Calendar.current.startOfDay(for: .now)
    ) ?? .now
  }

  private func minutes(for date: Date) -> Int {
    let components = Calendar.current.dateComponents([.hour, .minute], from: date)
    return (components.hour ?? 0) * 60 + (components.minute ?? 0)
  }

  private func weekdayName(_ weekday: Int) -> String {
    Calendar.current.shortWeekdaySymbols[weekday - 1]
  }

  private func toggleWeekday(_ weekday: Int) {
    if draft.wbtbWeekdays.contains(weekday) {
      draft.wbtbWeekdays.removeAll { $0 == weekday }
    } else if draft.wbtbWeekdays.count < 2 {
      draft.wbtbWeekdays.append(weekday)
    }
  }
}
