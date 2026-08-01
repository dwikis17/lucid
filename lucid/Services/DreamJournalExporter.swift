import Foundation

enum DreamJournalExporter {
  static func markdown(for entries: [DreamEntry]) -> String {
    entries
      .filter { $0.hasContent }
      .sorted { $0.dreamDate < $1.dreamDate }
      .map { entry in
        let draft = entry.isDraft ? "\n\n> Draft" : ""
        return "# \(entry.displayTitle)\n\n" +
          "Date: \(entry.dreamDate.formatted(date: .long, time: .omitted))\n" +
          "Lucidity: \(entry.lucidity.title)\n\n" +
          "\(entry.content)\(draft)"
      }
      .joined(separator: "\n\n---\n\n")
  }
}
