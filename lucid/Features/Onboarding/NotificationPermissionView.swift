import SwiftUI

struct NotificationPermissionView: View {
  @Environment(AppModel.self) private var appModel
  @Binding var hasCompletedOnboarding: Bool
  @State private var isRequesting = false

  var body: some View {
    VStack(spacing: 24) {
      Image(systemName: "bell.circle")
        .symbolRenderingMode(.hierarchical)
        .lucidHeroSymbol()
        .accessibilityHidden(true)

      Text("Allow gentle reminders")
        .font(.title)
        .bold()
        .multilineTextAlignment(.center)

      Text(
        "Notifications power daytime reality checks. You can continue without them and " +
          "enable them later in Settings."
      )
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.center)

      Button(
        "Allow Notifications",
        systemImage: "bell.badge",
        action: didTapAllowButton
      )
      .lucidPrimaryButton()
      .controlSize(.large)
      .disabled(isRequesting)

      Button("Not Now", action: didTapNotNowButton)
        .buttonStyle(.bordered)
        .frame(minHeight: 44)
    }
    .padding()
    .lucidScreenBackground()
  }

  private func didTapAllowButton() {
    isRequesting = true
    Task {
      await appModel.requestNotificationPermission()
      isRequesting = false
      hasCompletedOnboarding = true
    }
  }

  private func didTapNotNowButton() {
    hasCompletedOnboarding = true
  }
}
