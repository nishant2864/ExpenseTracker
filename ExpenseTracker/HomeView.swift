import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: FinanceStore
    let namespace: Namespace.ID
    let onAddTransaction: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if store.hasTransactions {
                    BalanceHeroCard(snapshot: store.monthlySnapshot, namespace: namespace)
                    QuickStatsRow(snapshot: store.monthlySnapshot)
                    SpendingChartCard(items: store.monthlyTotalsByCategory(kind: .expense), formatter: store.formattedCurrency)
                    recentSection
                } else {
                    FirstRunHomeCard(action: onAddTransaction)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .background(AppBackdrop().ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: ProfileView()) {
                    Image(systemName: "person.crop.circle")
                        .font(.title2)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.system(.largeTitle, weight: .bold))
                    Text("Your money is organized for \(store.selectedMonth.formatted(.dateTime.month(.wide)))")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                MonthPicker(
                    selectedMonth: Binding(
                        get: { store.selectedMonth },
                        set: { store.selectedMonth = $0 }
                    )
                )
            }
            .contentTransition(.numericText())
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent activity")
                .font(.title3.bold())

            if store.recentTransactions.isEmpty {
                EmptyStateCard(
                    title: "No transactions yet",
                    subtitle: "Start by adding your first income or expense and the monthly story will build itself.",
                    systemImage: "tray.fill"
                )
            } else {
                ForEach(store.recentTransactions) { item in
                    TransactionRow(item: item, formattedAmount: store.formattedCurrency(item.amount))
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        return switch hour {
        case 5..<12: "Good Morning"
        case 12..<17: "Good Afternoon"
        default: "Good Evening"
        }
    }
}
