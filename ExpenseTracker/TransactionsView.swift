import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var selectedFilter: TransactionKind?

    var body: some View {
        List {
            Section {
                Picker("Filter", selection: $selectedFilter) {
                    Text("All").tag(TransactionKind?.none)
                    ForEach(TransactionKind.allCases) { kind in
                        Text(kind.title).tag(TransactionKind?.some(kind))
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            if store.transactions(for: selectedFilter).isEmpty {
                Section {
                    EmptyStateCard(
                        title: "This month is quiet",
                        subtitle: "Add a few transactions to unlock category tracking and summaries.",
                        systemImage: "moon.stars.fill"
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            } else {
                ForEach(groupedTransactions, id: \.date) { section in
                    Section(section.date.formatted(.dateTime.weekday(.wide).day().month())) {
                        ForEach(section.items) { item in
                            TransactionRow(item: item, formattedAmount: store.formattedCurrency(item.amount))
                                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                .listRowBackground(Color.clear)
                        }
                        .onDelete { offsets in
                            store.deleteTransactions(at: offsets, in: section.items)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppBackdrop().ignoresSafeArea())
        .navigationTitle("Transactions")
    }

    private var groupedTransactions: [(date: Date, items: [TransactionItem])] {
        let items = store.transactions(for: selectedFilter)
        let grouped = Dictionary(grouping: items) { Calendar.current.startOfDay(for: $0.date) }
        return grouped
            .map { (date: $0.key, items: $0.value) }
            .sorted { $0.date > $1.date }
    }
}
