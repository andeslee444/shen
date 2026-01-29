//
//  MainTabView.swift
//  Terrain
//
//  Main tab navigation after onboarding
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .today
    @Environment(\.terrainTheme) private var theme

    enum Tab: String, CaseIterable {
        case today = "Today"
        case rightNow = "Right Now"
        case ingredients = "Ingredients"
        case learn = "Learn"
        case progress = "Progress"

        var icon: String {
            switch self {
            case .today: return "sun.horizon.fill"
            case .rightNow: return "bolt.fill"
            case .ingredients: return "leaf.fill"
            case .learn: return "book.fill"
            case .progress: return "chart.line.uptrend.xyaxis"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label(Tab.today.rawValue, systemImage: Tab.today.icon)
                }
                .tag(Tab.today)

            RightNowView()
                .tabItem {
                    Label(Tab.rightNow.rawValue, systemImage: Tab.rightNow.icon)
                }
                .tag(Tab.rightNow)

            IngredientsView()
                .tabItem {
                    Label(Tab.ingredients.rawValue, systemImage: Tab.ingredients.icon)
                }
                .tag(Tab.ingredients)

            LearnView()
                .tabItem {
                    Label(Tab.learn.rawValue, systemImage: Tab.learn.icon)
                }
                .tag(Tab.learn)

            ProgressTabView()
                .tabItem {
                    Label(Tab.progress.rawValue, systemImage: Tab.progress.icon)
                }
                .tag(Tab.progress)
        }
        .tint(theme.colors.accent)
    }
}

#Preview {
    MainTabView()
        .environment(\.terrainTheme, TerrainTheme.default)
}
