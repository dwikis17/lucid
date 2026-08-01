import SwiftUI

struct AppLockView: View {
  @Environment(AppModel.self) private var appModel
  @State private var isUnlocking = false

  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "lock.circle.fill")
        .font(.system(size: 64))
        .foregroundStyle(LucidTheme.moonmint)
        .accessibilityHidden(true)

      Text("Lucid Cue is locked")
        .font(.title2)
        .bold()

      Text("Unlock to see your journal and progress.")
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      Button("Unlock", systemImage: "faceid") {
        Task { await unlock() }
      }
        .lucidPrimaryButton()
        .controlSize(.large)
        .disabled(isUnlocking)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .lucidScreenBackground()
    .task { await unlock() }
  }

  private func unlock() async {
    guard !isUnlocking else { return }
    isUnlocking = true
    _ = await appModel.appLock.unlock()
    isUnlocking = false
  }
}
