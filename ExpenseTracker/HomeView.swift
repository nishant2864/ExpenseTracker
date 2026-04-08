import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: FinanceStore
    let namespace: Namespace.ID
    let onAddTransaction: () -> Void

    @State private var showingIncome = false
    @State private var showingExpenses = false
    @State private var showingAllActivity = false

    var body: some View {
        ScrollView {

            VStack(alignment: .leading, spacing: 20) {
                header
                // Card is always visible — shows glass placeholder until generated
                ATMCardView(snapshot: store.monthlySnapshot, namespace: namespace)
                if store.hasTransactions {
                    QuickStatsRow(
                        snapshot: store.monthlySnapshot,
                        onIncomeTap: { showingIncome = true },
                        onExpenseTap: { showingExpenses = true }
                    )
                    SpendingChartCard(
                        items: store.monthlyTotalsByCategory(kind: .expense),
                        formatter: store.formattedCurrency
                    )
                    recentSection
                } else {
                    FirstRunHomeCard(action: onAddTransaction)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
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
        .sheet(isPresented: $showingIncome) {
            TransactionKindDetailView(kind: .income)
                .environmentObject(store)
        }
        .sheet(isPresented: $showingExpenses) {
            TransactionKindDetailView(kind: .expense)
                .environmentObject(store)
        }
        .sheet(isPresented: $showingAllActivity) {
            AllRecentActivityView()
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
            HStack(alignment: .center) {
                Text("Recent activity")
                    .font(.title3.bold())

                Spacer()

                if !store.recentTransactions.isEmpty {
                    Button {
                        showingAllActivity = true
                    } label: {
                        HStack(spacing: 3) {
                            Text("See all")
                                .font(.subheadline.weight(.medium))
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }

            if store.recentTransactions.isEmpty {
                EmptyStateCard(
                    title: "No transactions yet",
                    subtitle: "Start by adding your first income or expense and the monthly story will build itself.",
                    systemImage: "tray.fill"
                )
            } else {
                ForEach(Array(store.recentTransactions.prefix(3))) { item in
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
