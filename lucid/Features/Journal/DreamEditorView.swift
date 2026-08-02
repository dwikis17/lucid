import SwiftData
import SwiftUI

struct DreamEditorView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.modelContext) private var modelContext
  @Bindable var dream: DreamEntry
  @State private var validationMessage: String?
  @State private var isEditorVisible = false

  var body: some View {
    Form {
      Section("Dream") {
        TextField("Title (optional)", text: $dream.title)
          .textInputAutocapitalization(.sentences)
        DatePicker("Dream date", selection: $dream.dreamDate, displayedComponents: .date)
        TextEditor(text: $dream.content)
          .frame(minHeight: 220)
          .overlay(alignment: .topLeading) {
            if dream.content.isEmpty {
              Text("What do you remember?")
                .foregroundStyle(.secondary)
                .padding(.top, 8)
                .padding(.leading, 5)
                .allowsHitTesting(false)
            }
          }
      }

      Section("Awareness") {
        Picker("Lucidity", selection: $dream.lucidityRawValue) {
          ForEach(LucidityLevel.allCases, id: \.rawValue) { level in
            Label(level.title, systemImage: level.symbol)
              .tag(level.rawValue)
          }
        }
        .pickerStyle(.navigationLink)

        HStack {
          Image(systemName: dream.lucidity.symbol)
            .foregroundStyle(LucidTheme.moonmint)
          Text(dream.lucidity.title)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Lucidity: \(dream.lucidity.title)")
      }

      if let validationMessage {
        Section {
          Label(validationMessage, systemImage: "exclamationmark.circle")
            .foregroundStyle(.red)
        }
      }
    }
    .scrollContentBackground(.hidden)
    .lucidScreenBackground()
    .navigationTitle(dream.displayTitle)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Close", systemImage: "xmark") { dismiss() }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Done", systemImage: "checkmark", action: finish)
      }
    }
    .onChange(of: dream.title) { _, _ in saveDraft() }
    .onChange(of: dream.content) { _, _ in saveDraft() }
    .onChange(of: dream.dreamDate) { _, _ in saveDraft() }
    .onChange(of: dream.lucidityRawValue) { _, _ in saveDraft() }
    .onDisappear { saveDraft() }
    .scaleEffect(isEditorVisible ? 1 : 0.92)
    .opacity(isEditorVisible ? 1 : 0)
    .onAppear(perform: animatePresentation)
  }

  private func animatePresentation() {
    guard !reduceMotion else {
      isEditorVisible = true
      return
    }

    withAnimation(.easeOut(duration: 0.35)) {
      isEditorVisible = true
    }
  }

  private func finish() {
    guard dream.hasContent else {
      validationMessage = "Add a few words before saving this dream."
      return
    }
    dream.isDraft = false
    dream.updatedAt = .now
    try? modelContext.save()
    dismiss()
  }

  private func saveDraft() {
    dream.updatedAt = .now
    try? modelContext.save()
  }
}
