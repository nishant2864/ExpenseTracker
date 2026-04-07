//
//  ContentView.swift
//  ExpenseTracker
//

import Charts
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var selectedTab: AppTab = .home
    @State private var showComposer = false
    @Namespace private var cardNamespace

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(namespace: cardNamespace) {
                    showComposer = true
                }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(AppTab.home)

            NavigationStack {
                TransactionsView()
            }
            .tabItem {
                Label("Transactions", systemImage: "arrow.left.arrow.right")
            }
            .tag(AppTab.transactions)

            NavigationStack {
                InsightsView()
            }
            .tabItem {
                Label("Insights", systemImage: "chart.pie.fill")
            }
            .tag(AppTab.insights)
        }
        .overlay(alignment: .bottomTrailing) {
            AddTransactionButton {
                showComposer = true
            }
            .padding(.trailing, 22)
            .padding(.bottom, 88)
        }
        .sheet(isPresented: $showComposer) {
            AddTransactionView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .preferredColorScheme(store.appearance.colorScheme)
        .animation(.snappy(duration: 0.35), value: selectedTab)
    }
}

private enum AppTab: Hashable {
    case home
    case transactions
    case insights
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(FinanceStore())
    }
}
