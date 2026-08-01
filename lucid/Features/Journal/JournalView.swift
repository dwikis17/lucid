import SwiftData
import SwiftUI

struct JournalView: View {
  @Environment(AppModel.self) private var appModel
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \DreamEntry.dreamDate, order: .reverse)
  private var entries: [DreamEntry]
  @State private var searchText = ""

  private var visibleEntries: [DreamEntry] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else { return entries }
    return entries.filter {
      $0.title.localizedStandardContains(query) ||
        $0.content.localizedStandardContains(query)
    }
  }

  var body: some View {
    Group {
      if entries.isEmpty {
        ContentUnavailableView {
          Label("No dreams yet", systemImage: "moon.stars")
        } description: {
          Text("Write down what you remember before it fades.")
        } actions: {
          Button("Record a Dream", systemImage: "square.and.pencil") {
            appModel.beginDreamEntry()
          }
          .lucidPrimaryButton()
        }
      } else if visibleEntries.isEmpty {
        ContentUnavailableView.search(text: searchText)
      } else {
        List {
          ForEach(visibleEntries) { entry in
            NavigationLink {
              DreamEditorView(dream: entry)
            } label: {
              DreamRow(entry: entry)
            }
          }
          .onDelete(perform: deleteEntries)
        }
        .scrollContentBackground(.hidden)
      }
    }
    .lucidScreenBackground()
    .navigationTitle("Journal")
    .searchable(text: $searchText, prompt: "Search dreams")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("Record a Dream", systemImage: "square.and.pencil") {
          appModel.beginDreamEntry()
        }
        .accessibilityLabel("Record a new dream")
      }
    }
  }

  private func deleteEntries(at offsets: IndexSet) {
    for index in offsets {
      modelContext.delete(visibleEntries[index])
    }
    try? modelContext.save()
  }
}

private struct DreamRow: View {
  let entry: DreamEntry

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: entry.lucidity.symbol)
        .foregroundStyle(LucidTheme.moonmint)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(entry.displayTitle)
            .font(.headline)
          if entry.isDraft {
            Text("Draft")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        if !entry.previewText.isEmpty {
          Text(entry.previewText)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
        Text(entry.dreamDate, format: .dateTime.weekday().month().day())
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(entry.displayTitle), \(entry.lucidity.title)")
  }
}
