import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var selectedFilter: TransactionKind?
    @State private var searchText: String = ""

    var body: some View {
        List {
            // Filter picker
            Section {
                Picker("Filter", selection: $selectedFilter) {
                    Text("All").tag(TransactionKind?.none)
                    ForEach(TransactionKind.allCases) { kind in
                        Text(kind.title).tag(TransactionKind?.some(kind))
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if filteredTransactions.isEmpty {
                Section {
                    EmptyStateCard(
                        title: searchText.isEmpty ? "This month is quiet" : "No results",
                        subtitle: searchText.isEmpty
                            ? "Add a few transactions to unlock category tracking and summaries."
                            : "No transactions match \"\(searchText)\".",
                        systemImage: searchText.isEmpty ? "moon.stars.fill" : "magnifyingglass"
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .padding(.horizontal)
            } else {
                ForEach(groupedTransactions, id: \.date) { section in
                    Section(section.date.formatted(.dateTime.weekday(.wide).day().month())) {
                        ForEach(section.items) { item in
                            TransactionRow(item: item, formattedAmount: store.formattedCurrency(item.amount))
                                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            store.deleteTransactions(at: offsets, in: section.items)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppBackdrop().ignoresSafeArea())
        .navigationTitle("Transactions")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search transactions")
    }

    // MARK: - Filtering

    private var filteredTransactions: [TransactionItem] {
        let byKind = store.transactions(for: selectedFilter)
        guard !searchText.isEmpty else { return byKind }
        let query = searchText.lowercased()
        return byKind.filter {
            $0.categoryTitle.lowercased().contains(query) ||
            $0.note.lowercased().contains(query)
        }
    }

    private var groupedTransactions: [(date: Date, items: [TransactionItem])] {
        let grouped: [Date: [TransactionItem]] = Dictionary(grouping: filteredTransactions) {
            Calendar.current.startOfDay(for: $0.date)
        }
        return grouped
            .map { (date: $0.key, items: $0.value) }
            .sorted { $0.date > $1.date }
    }
}
