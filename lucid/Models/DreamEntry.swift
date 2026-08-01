import Foundation
import SwiftData

@Model
final class DreamEntry {
  var id: UUID = UUID()
  var createdAt: Date = Date.now
  var updatedAt: Date = Date.now
  var dreamDate: Date = Date.now
  var title: String = ""
  var content: String = ""
  var lucidityRawValue: Int = LucidityLevel.unaware.rawValue
  var isDraft: Bool = true

  init(
    id: UUID = UUID(),
    createdAt: Date = .now,
    updatedAt: Date = .now,
    dreamDate: Date = .now,
    title: String = "",
    content: String = "",
    lucidity: LucidityLevel = .unaware,
    isDraft: Bool = true
  ) {
    self.id = id
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.dreamDate = dreamDate
    self.title = title
    self.content = content
    lucidityRawValue = lucidity.rawValue
    self.isDraft = isDraft
  }

  var lucidity: LucidityLevel {
    get { LucidityLevel(rawValue: lucidityRawValue) ?? .unaware }
    set { lucidityRawValue = newValue.rawValue }
  }

  var displayTitle: String {
    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedTitle.isEmpty ? "Untitled dream" : trimmedTitle
  }

  var previewText: String {
    content.trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "\n", with: " ")
  }

  var hasContent: Bool {
    !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}
