//
//  MainTabView.swift
//  Terrain
//
//  Main tab navigation after onboarding
//  New structure: Home, Do, Ingredients, Learn, You
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var coordinator = NavigationCoordinator()
    @Environment(\.terrainTheme) private var theme
    @Query private var cabinetItems: [UserCabinet]

    var body: some View {
        TabView(selection: tabSelection) {
            // Home tab - insight + meaning + direction (Co-Star style)
            HomeView()
                .tabItem {
                    Label(
                        NavigationCoordinator.Tab.home.title,
                        systemImage: NavigationCoordinator.Tab.home.icon
                    )
                }
                .tag(NavigationCoordinator.Tab.home)

            // Do tab - execution (capsule + quick fixes combined)
            DoView()
                .tabItem {
                    Label(
                        NavigationCoordinator.Tab.do.title,
                        systemImage: NavigationCoordinator.Tab.do.icon
                    )
                }
                .tag(NavigationCoordinator.Tab.do)

            // Ingredients tab - unchanged
            IngredientsView()
                .tabItem {
                    Label(
                        NavigationCoordinator.Tab.ingredients.title,
                        systemImage: NavigationCoordinator.Tab.ingredients.icon
                    )
                }
                .tag(NavigationCoordinator.Tab.ingredients)
                .badge(cabinetItems.count)

            // Learn tab - unchanged
            LearnView()
                .tabItem {
                    Label(
                        NavigationCoordinator.Tab.learn.title,
                        systemImage: NavigationCoordinator.Tab.learn.icon
                    )
                }
                .tag(NavigationCoordinator.Tab.learn)

            // You tab - progress + settings combined
            YouView()
                .tabItem {
                    Label(
                        NavigationCoordinator.Tab.you.title,
                        systemImage: NavigationCoordinator.Tab.you.icon
                    )
                }
                .tag(NavigationCoordinator.Tab.you)
        }
        .tint(theme.colors.accent)
        .environment(coordinator)
    }

    /// Binding to the coordinator's selected tab for two-way sync
    private var tabSelection: Binding<NavigationCoordinator.Tab> {
        Binding(
            get: { coordinator.selectedTab },
            set: { coordinator.selectedTab = $0 }
        )
    }
}

#Preview {
    MainTabView()
        .environment(\.terrainTheme, TerrainTheme.default)
}
