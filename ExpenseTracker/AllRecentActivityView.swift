import SwiftUI

// MARK: - All Recent Activity Sheet
// Presented modally from "See all" in HomeView's recent activity section.

struct AllRecentActivityView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    /// All transactions across all time, newest first
    private var allTransactions: [TransactionItem] {
        store.transactions.sorted { $0.date > $1.date }
    }

    /// Group transactions by calendar day for display sectioning
    private var groupedByDay: [(date: Date, items: [TransactionItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: allTransactions) { item in
            calendar.startOfDay(for: item.date)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, items: $0.value) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop().ignoresSafeArea()

                if allTransactions.isEmpty {
                    emptyState
                } else {
                    transactionList
                }
            }
            .navigationTitle("Recent Activity")
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

    // MARK: - Grouped list

    private var transactionList: some View {
        ScrollView {

            LazyVStack(alignment: .leading, spacing: 24, pinnedViews: .sectionHeaders) {
                ForEach(groupedByDay, id: \.date) { group in
                    Section {
                        VStack(spacing: 0) {
                            ForEach(group.items) { item in
                                TransactionRow(
                                    item: item,
                                    formattedAmount: store.formattedCurrency(item.amount)
                                )
                                .padding(.vertical, 4)

                                if item.id != group.items.last?.id {
                                    Divider()
                                        .opacity(0.25)
                                        .padding(.leading, 56)
                                }
                            }
                        }
                    } header: {
                        dayHeader(for: group.date, count: group.items.count)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Day header

    private func dayHeader(for date: Date, count: Int) -> some View {
        HStack(spacing: 8) {
            Text(sectionTitle(for: date))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(count) \(count == 1 ? "entry" : "entries")")
                .font(.caption.weight(.medium))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            // Frosted backing so header stays readable when pinned
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .horizontal)
                .opacity(0.0) // let AppBackdrop show; remove opacity to make sticky opaque
        )
    }

    private func sectionTitle(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.day().month(.wide).year())
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack {
            Spacer()
            EmptyStateCard(
                title: "No activity yet",
                subtitle: "Your transactions will appear here once you start adding income or expenses.",
                systemImage: "clock.arrow.circlepath"
            )
            .padding(.horizontal, 24)
            Spacer()
        }
    }
}
