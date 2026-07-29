import SwiftUI

struct SetupView: View {
  @Environment(AppModel.self) private var appModel
  @State private var draft = CueSettings.defaultValue
  @State private var daytimeStart = Date.now
  @State private var daytimeEnd = Date.now
  @State private var bedtime = Date.now
  @State private var isLoaded = false
  @State private var validationErrors: [String] = []
  @State private var isSaving = false

  var body: some View {
    Form {
      Section("Cue") {
        TextField("Cue word", text: $draft.cueWord)
          .textInputAutocapitalization(.words)
        Picker("Watch haptic preview", selection: $draft.selectedHaptic) {
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

      Section("Nighttime cue") {
        Toggle("Nighttime cue", isOn: $draft.isNightCueEnabled)
        DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
        Picker("Delay after bedtime", selection: $draft.nightCueDelayHours) {
          ForEach([4, 5, 6], id: \.self) { hours in
            Text("\(hours) hours").tag(hours)
          }
        }
        .disabled(!draft.isNightCueEnabled)
        Text(
          "The watch schedules one gentle notification. The system controls exact " +
            "delivery and its notification haptic."
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
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

      Section {
        Button("Save & Schedule", systemImage: "checkmark", action: didTapSaveButton)
          .disabled(isSaving)
      }
    }
    .onAppear(perform: loadSettings)
  }

  private func loadSettings() {
    guard !isLoaded else { return }
    draft = appModel.settings
    daytimeStart = date(for: draft.daytimeStartMinutes)
    daytimeEnd = date(for: draft.daytimeEndMinutes)
    bedtime = date(for: draft.bedtimeMinutes)
    isLoaded = true
  }

  private func didTapSaveButton() {
    draft.daytimeStartMinutes = minutes(for: daytimeStart)
    draft.daytimeEndMinutes = minutes(for: daytimeEnd)
    draft.bedtimeMinutes = minutes(for: bedtime)
    validationErrors = CueSettingsValidator.errors(for: draft)
    guard validationErrors.isEmpty else { return }

    isSaving = true
    Task {
      _ = await appModel.save(settings: draft)
      isSaving = false
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
}
