import RevenueCat
import RevenueCatUI
import SwiftUI

struct ProUpgradeView: View {
  @Environment(AppModel.self) private var appModel
  @State private var isPaywallPresented = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Image(systemName: "sparkles")
          .font(.system(size: 48))
          .foregroundStyle(LucidTheme.moonmint)
          .accessibilityHidden(true)

        Text("Lucid Cue Pro")
          .font(.largeTitle)
          .bold()

        Text("Build a calmer, more consistent lucid-dream practice.")
          .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 12) {
          benefit("Scheduled reality-check cues")
          benefit("Guided WBTB + MILD sessions")
          benefit("Longer progress trends and Markdown export")
        }

        if appModel.purchaseManager.isPro {
          Label("Pro is unlocked", systemImage: "checkmark.seal.fill")
            .foregroundStyle(LucidTheme.moonmint)
        } else if appModel.purchaseManager.currentOffering != nil {
          Button("View Pro options", systemImage: "lock.open") {
            isPaywallPresented = true
          }
          .lucidPrimaryButton()
          .controlSize(.large)
          .frame(maxWidth: .infinity)
        } else if appModel.purchaseManager.isLoading {
          ProgressView("Loading Pro")
            .frame(maxWidth: .infinity)
        } else {
          VStack(spacing: 12) {
            Text(appModel.purchaseManager.message ?? "Pro options are unavailable right now.")
              .font(.footnote)
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity)
            Button("Try Again", action: refresh)
              .buttonStyle(.bordered)
          }
          .frame(maxWidth: .infinity)
        }

        Button("Restore Purchases", action: restore)
          .buttonStyle(.bordered)
          .frame(maxWidth: .infinity)

        if let message = appModel.purchaseManager.message {
          Text(message)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
        }
      }
      .padding()
    }
    .lucidScreenBackground()
    .navigationTitle("Pro")
    .sheet(isPresented: $isPaywallPresented) {
      PaywallView(displayCloseButton: true)
        .onPurchaseCompleted { customerInfo in
          purchaseCompleted(customerInfo)
        }
        .onRestoreCompleted { customerInfo in
          purchaseCompleted(customerInfo)
        }
    }
    .task { await appModel.purchaseManager.start() }
  }

  private func benefit(_ text: String) -> some View {
    Label(text, systemImage: "checkmark.circle")
  }

  private func refresh() {
    Task {
      await appModel.purchaseManager.refresh()
    }
  }

  private func restore() {
    Task {
      await appModel.purchaseManager.restore()
      await appModel.didBecomeActive()
    }
  }

  private func purchaseCompleted(_ customerInfo: RevenueCat.CustomerInfo) {
    appModel.purchaseManager.apply(customerInfo)
    Task {
      await appModel.didBecomeActive()
    }
  }
}
