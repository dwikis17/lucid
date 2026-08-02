import SwiftData
import SwiftUI

struct JournalView: View {
  @Environment(AppModel.self) private var appModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \DreamEntry.dreamDate, order: .reverse)
  private var entries: [DreamEntry]
  @State private var searchText = ""
  @State private var selectedTab: JournalTab = .all

  private var visibleEntries: [DreamEntry] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    let selectedLucidity = selectedTab.lucidityLevel

    return entries.filter { entry in
      let matchesLevel = selectedLucidity.map { entry.lucidity == $0 } ?? true
      let matchesSearch = query.isEmpty ||
        entry.title.localizedStandardContains(query) ||
        entry.content.localizedStandardContains(query)
      return matchesLevel && matchesSearch
    }
  }

  var body: some View {
    ZStack {
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
        if selectedTab != .all && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          ContentUnavailableView {
            Label("No \(selectedTab.title) dreams", systemImage: selectedTab.symbol)
          } description: {
            Text("Try another lucidity level or record a new dream.")
          } actions: {
            Button("Show All", systemImage: "square.grid.2x2") {
              selectedTab = .all
            }
            .lucidPrimaryButton()
          }
          .transition(.opacity.combined(with: .scale(scale: 0.98)))
        } else {
          ContentUnavailableView.search(text: searchText)
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
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
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
      }
    }
    .animation(
      reduceMotion ? nil : .easeInOut(duration: 0.25),
      value: selectedTab
    )
    .safeAreaInset(edge: .top, spacing: 0) {
      if !entries.isEmpty {
        JournalTabBar(selection: $selectedTab)
          .padding(.horizontal)
          .padding(.vertical, 8)
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

private extension JournalTab {
  var lucidityLevel: LucidityLevel? {
    switch self {
    case .all: nil
    case .unaware: .unaware
    case .suspicious: .suspicious
    case .brief: .brief
    case .clear: .clear
    case .sustained: .sustained
    case .throughout: .throughout
    }
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
