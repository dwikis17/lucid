//
//  Animation.swift
//  lucid
//
//  Created by Dwiki on 02/08/26.
//

import SwiftUI

protocol JournalTabItem: CaseIterable, Equatable, Hashable {
    var symbol: String { get }
    var title: String { get }
    var activeTint: Color { get }
    var activeBackground: Color { get }

}
struct JournalTabBar<Tab: JournalTabItem>: View {
    
    var spacing: CGFloat = 8
    var trailingVisibility: CGFloat = 15
    var isGestureEnabled = false
    @Binding var selection: Tab
    //used to calculate the inactive tab width to sync animations perfectly
    
    @State private var tabTitleSizes: [Tab:CGSize] = [:]
    var body: some View {
        GeometryReader {
            let containerSize = $0.size
            let activeTitleWidth = tabTitleSizes[selection]?.width ?? 0
            
            let activeWidth = activeTitleWidth + 60 + 6
            let inActiveWidth = (containerSize.width - activeWidth) / CGFloat(allTabs.count - 1)
            
            HStack(spacing: spacing) {
                ForEach(allTabs, id: \.title) { tab in
                    TabItemView(tab, inActiveWidth: inActiveWidth)
                }
            }
        }
        .frame(height: 38)
        .animation(animation, value: selection)
     
    }
    
    @ViewBuilder
    func TabItemView(_ tab: Tab, inActiveWidth: CGFloat) -> some View {
        let isActive = selection == tab
        Button {
            selection = tab
        } label: {
            HStack(spacing: isActive ? 6 : 0) {
                Image(systemName: tab.symbol)
                    .font(.body)
                    .frame(width: 20)

                Text(tab.title)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: true, vertical: false)
                    .onGeometryChange(for: CGSize.self) { geo in
                        geo.size
                    } action: { newValue in
                        tabTitleSizes[tab] = newValue
                    }
                    .frame(width: isActive ? nil : 0, alignment: .leading)
                    .opacity(isActive ? 1 : 0)
            }
            .foregroundStyle(isActive ? tab.activeTint : .gray)
            .padding(.horizontal, isActive ? 20 : 0)
            .frame(maxHeight: .infinity)
            .frame(maxWidth: isActive ? nil : inActiveWidth)
            .background {
                ZStack {
                    Capsule()
                        .fill(.fill)
                        .opacity(isActive ? 0 : 1)

                    Capsule()
                        .fill(tab.activeBackground)
                        .opacity(isActive ? 1 : 0)
                }
            }
            .clipShape(.capsule)
            .contentShape(.capsule)
            .geometryGroup()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
    }
    
    var allTabs: [Tab.AllCases.Element] {
        Array(Tab.allCases)
    }
    
    //animation
    
    var animation: Animation {
        .interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0)
    }
}

// sample tab item
enum JournalTab: JournalTabItem {
    case all
    case unaware
    case suspicious
    case brief
    case clear
    case sustained
    case throughout

    var symbol: String {
        switch self {
        case .all: "square.grid.2x2"
        case .unaware: "moon"
        case .suspicious: "moon.haze"
        case .brief: "moon.stars"
        case .clear: "moon.stars.fill"
        case .sustained: "sparkles"
        case .throughout: "sun.max.fill"
        }
    }
    
    var title: String {
        return switch self {
        case .all: "All"
        case .brief: "Briefly"
        case .suspicious: "Suspicious"
        case .clear: "Clear"
        case .sustained: "Sustained"
        case .unaware: "Unaware"
        case .throughout: "Throughout"
        }
    }

    var activeTint: Color {
        switch self {
        case .all: LucidTheme.deepTwilight
        case .unaware: .accent
        case .suspicious: .orange
        case .brief: .teal
        case .clear: .blue
        case .sustained: .purple
        case .throughout: .indigo
        }
    }

    var activeBackground: Color {
        switch self {
        case .all: LucidTheme.moonlight
        case .unaware: .accent.opacity(0.2)
        case .suspicious: .orange.opacity(0.22)
        case .brief: .teal.opacity(0.22)
        case .clear: .blue.opacity(0.22)
        case .sustained: .purple.opacity(0.22)
        case .throughout: .indigo.opacity(0.22)
        }
    }
}

struct TestView: View {
    @State private var activeTab: JournalTab = .all
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                JournalTabBar(selection: $activeTab)
            }
            .safeAreaPadding(15)
            .navigationTitle("Test")
        }
    }
}


#Preview {
    TestView()
}
