import SwiftUI

// MARK: - App Navigation State

enum AppFlowState {
    case launch
    case onboarding
    case setup
    case main
}

// MARK: - Root Coordinator

struct RootCoordinator: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var flowState: AppFlowState = .launch

    var body: some View {
        ZStack {
            switch flowState {
            case .launch:
                LaunchScreenView {
                    transitionAfterLaunch()
                }
                .transition(.opacity)

            case .onboarding:
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        flowState = .setup
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .setup:
                UserSetupView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        flowState = .main
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .main:
                MainAppView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.45), value: flowState)
        .preferredColorScheme(store.appearance.colorScheme)
    }

    private func transitionAfterLaunch() {
        withAnimation(.easeInOut(duration: 0.45)) {
            flowState = store.hasCompletedOnboarding ? .main : .onboarding
        }
    }
}

// MARK: - Main App View 

struct MainAppView: View {
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
        .animation(.snappy(duration: 0.35), value: selectedTab)
    }
}

private enum AppTab: Hashable {
    case home
    case transactions
    case insights
}
