import SwiftUI

// MARK: - Transaction Kind Detail Sheet
// Presented modally when the user taps Income or Expenses on the home screen.

struct TransactionKindDetailView: View {
    let kind: TransactionKind
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    private var title: String {
        kind == .income ? "Income" : "Expenses"
    }

    private var tint: Color {
        kind == .income ? .green : .red
    }

    private var icon: String {
        kind == .income ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill"
    }

    private var items: [TransactionItem] {
        store.transactions(for: kind)
    }

    private var total: Double {
        items.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop().ignoresSafeArea()

                ScrollView {

                    VStack(spacing: 20) {
                        summaryHero

                        if items.isEmpty {
                            emptyState
                        } else {
                            transactionsList
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }

    // MARK: - Summary hero

    private var summaryHero: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(tint.opacity(0.18))
                            .frame(width: 52, height: 52)
                        Image(systemName: icon)
                            .font(.system(size: 26))
                            .foregroundStyle(tint)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(store.selectedMonth.formatted(.dateTime.month(.wide).year()))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Text("\(items.count) transactions")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: Capsule())
                }



                VStack(alignment: .leading, spacing: 4) {
                    Text("Total \(title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(store.formattedCurrency(total))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(tint)
                        .contentTransition(.numericText())
                }
            }
        }
    }

    // MARK: - Transactions list

    private var transactionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All \(title)")
                .font(.title3.bold())
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(items) { item in
                    TransactionRow(item: item, formattedAmount: store.formattedCurrency(item.amount))
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        EmptyStateCard(
            title: "No \(title.lowercased()) this month",
            subtitle: "Transactions you add for \(store.selectedMonth.formatted(.dateTime.month(.wide))) will appear here.",
            systemImage: kind == .income ? "arrow.down.left.circle" : "arrow.up.right.circle"
        )
    }
}
