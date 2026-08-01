import SwiftUI

struct StatusMessageView: View {
  let message: String
  let dismiss: () -> Void

  var body: some View {
    HStack(alignment: .top) {
      Image(systemName: "info.circle.fill")
        .foregroundStyle(.tint)
        .accessibilityHidden(true)
      Text(message)
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
      Button("Dismiss", systemImage: "xmark", action: dismiss)
        .labelStyle(.iconOnly)
        .accessibilityLabel("Dismiss status")
    }
    .lucidCard(cornerRadius: 12)
  }
}
