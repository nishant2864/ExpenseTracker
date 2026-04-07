import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ProfileHeaderCard()
                settingsCard
                EmptyStateCard(
                    title: "Built for calm money decisions",
                    subtitle: "The interface stays focused on one thing at a time, with your balance, trends, and actions always within reach.",
                    systemImage: "sparkles"
                )
            }
            .padding(20)
            .padding(.bottom, 120)
        }
        .background(AppBackdrop().ignoresSafeArea())
        .navigationTitle("Profile")
    }

    private var settingsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Appearance")
                    .font(.title3.bold())

                Picker(
                    "Appearance",
                    selection: Binding(
                        get: { store.appearance },
                        set: { store.appearance = $0 }
                    )
                ) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: store.appearance) { _, newValue in
                    store.setAppearance(newValue)
                }

                Divider()

                HStack {
                    StatPill(label: "Transactions", value: "\(store.currentMonthTransactions.count)")
                    StatPill(label: "Categories", value: "\(store.categories.count)")
                    StatPill(label: "Balance", value: store.formattedCurrency(store.monthlySnapshot.balance))
                }
            }
        }
    }
}
