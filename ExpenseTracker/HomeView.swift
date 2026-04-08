import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: FinanceStore
    let namespace: Namespace.ID
    let onAddTransaction: () -> Void

    @State private var showingIncome = false
    @State private var showingExpenses = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if store.hasTransactions {
                    ATMCardView(snapshot: store.monthlySnapshot, namespace: namespace)
                    QuickStatsRow(
                        snapshot: store.monthlySnapshot,
                        onIncomeTap: { showingIncome = true },
                        onExpenseTap: { showingExpenses = true }
                    )
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
            ToolbarItem(placement: .topBarLeading) {
                MonthPicker(
                    selectedMonth: Binding(
                        get: { store.selectedMonth },
                        set: { store.selectedMonth = $0 }
                    )
                )
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: ProfileView()) {
                    Image(systemName: "person.crop.circle")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }
            }
        }
        // Income detail sheet
        .sheet(isPresented: $showingIncome) {
            TransactionKindDetailView(kind: .income)
                .environmentObject(store)
        }
        // Expenses detail sheet
        .sheet(isPresented: $showingExpenses) {
            TransactionKindDetailView(kind: .expense)
                .environmentObject(store)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(greeting),")
                        .font(.system(.largeTitle, weight: .bold))
                    Text("\(store.userDisplayName)")
                        .font(.system(.largeTitle, weight: .bold))
                    Spacer()
                    Text("Your money is organised for \(store.selectedMonth.formatted(.dateTime.month(.wide)))")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .contentTransition(.numericText())
        }
    }

    // MARK: - Recent section

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

    // MARK: - Greeting

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        return switch hour {
        case 5..<12: "Good Morning"
        case 12..<17: "Good Afternoon"
        default: "Good Evening"
        }
    }
}
