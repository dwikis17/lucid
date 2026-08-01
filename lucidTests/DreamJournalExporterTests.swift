import Foundation
import Testing
@testable import lucid

struct DreamJournalExporterTests {
  @Test
  func markdownIncludesDateLucidityAndDraftMarker() {
    let entry = DreamEntry(
      dreamDate: Date(timeIntervalSince1970: 0),
      title: "The blue room",
      content: "I noticed the walls changing.",
      lucidity: .clear,
      isDraft: true
    )

    let markdown = DreamJournalExporter.markdown(for: [entry])

    #expect(markdown.contains("# The blue room"))
    #expect(markdown.contains("Lucidity: Clearly aware"))
    #expect(markdown.contains("> Draft"))
  }
}
