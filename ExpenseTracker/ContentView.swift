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

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(AppTab.profile)
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
    case profile
}

private struct HomeView: View {
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
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
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        default: "Good evening"
        }
    }
}

private struct TransactionsView: View {
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

private struct InsightsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var animationTrigger = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if store.hasTransactions {
                    SummaryRingCard(snapshot: store.monthlySnapshot, formatter: store.formattedCurrency, animationTrigger: animationTrigger)
                    CategoryBreakdownCard(title: "Expense categories", items: store.monthlyTotalsByCategory(kind: .expense), formatter: store.formattedCurrency)
                    CategoryBreakdownCard(title: "Income sources", items: store.monthlyTotalsByCategory(kind: .income), formatter: store.formattedCurrency)
                } else {
                    EmptyStateCard(
                        title: "Insights appear after your first entries",
                        subtitle: "Add income and expenses first. Then this tab will animate your monthly balance and category breakdown.",
                        systemImage: "chart.pie"
                    )
                }
            }
            .padding(20)
            .padding(.bottom, 120)
        }
        .background(AppBackdrop().ignoresSafeArea())
        .navigationTitle("Insights")
        .onAppear {
            animationTrigger += 1
        }
    }
}

private struct ProfileView: View {
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

private struct AddTransactionView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    @State private var kind: TransactionKind = .expense
    @State private var amount = ""
    @State private var selectedCategory = FinanceCategory.defaults[0]
    @State private var useCustomCategory = false
    @State private var customCategory = ""
    @State private var note = ""
    @State private var date = Date.now
    @FocusState private var focusedField: Field?
    @State private var showValidation = false

    private enum Field {
        case amount
        case customCategory
        case note
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    kindPicker
                    amountField
                    categorySection
                    dateSection
                    noteSection
                    saveButton
                }
                .padding(20)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppBackdrop().ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add transaction")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("Capture spending while it’s still fresh. A few details now make the monthly picture clear later.")
                .foregroundStyle(.secondary)
        }
    }

    private var kindPicker: some View {
        Picker("Type", selection: $kind.animation(.spring(duration: 0.35))) {
            ForEach(TransactionKind.allCases) { item in
                Text(item.title).tag(item)
            }
        }
        .pickerStyle(.segmented)
    }

    private var amountField: some View {
        inputCard(title: "Amount") {
            TextField(kind == .income ? "0" : "0", text: $amount)
                .keyboardType(.decimalPad)
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .amount)

            if showValidation && parsedAmount == nil {
                validationText("Enter a valid amount greater than zero.")
            }
        }
    }

    private var categorySection: some View {
        inputCard(title: "Category") {
            Toggle("Use custom category", isOn: $useCustomCategory.animation(.snappy))
                .tint(.primary)

            if useCustomCategory {
                TextField("Custom category name", text: $customCategory)
                    .focused($focusedField, equals: .customCategory)

                if showValidation && customCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    validationText("Add a category name.")
                }
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 12)], spacing: 12) {
                    ForEach(store.categories) { category in
                        CategoryChip(category: category, isSelected: selectedCategory.id == category.id)
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.35)) {
                                    selectedCategory = category
                                }
                            }
                    }
                }
            }
        }
    }

    private var dateSection: some View {
        inputCard(title: "Date") {
            DatePicker("Transaction date", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
        }
    }

    private var noteSection: some View {
        inputCard(title: "Note") {
            TextField("Optional note", text: $note, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
                .focused($focusedField, equals: .note)
        }
    }

    private var saveButton: some View {
        Button {
            showValidation = true
            guard let transaction = buildTransaction() else { return }
            withAnimation(.spring(duration: 0.5)) {
                store.addTransaction(transaction)
            }
            dismiss()
        } label: {
            Text("Save transaction")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [.white, Color.white.opacity(0.88)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    private func buildTransaction() -> TransactionItem? {
        guard let amount = parsedAmount else { return nil }

        if useCustomCategory {
            let title = customCategory.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { return nil }
            let palette = FinanceCategory.customPalette[abs(title.hashValue) % FinanceCategory.customPalette.count]
            let symbol = kind == .income ? "sparkles.rectangle.stack" : "seal.fill"

            return TransactionItem(
                kind: kind,
                amount: amount,
                categoryID: nil,
                categoryTitle: title,
                categorySymbol: symbol,
                categoryColors: palette,
                date: date,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        return TransactionItem(
            kind: kind,
            amount: amount,
            categoryID: selectedCategory.id,
            categoryTitle: selectedCategory.title,
            categorySymbol: selectedCategory.symbol,
            categoryColors: selectedCategory.colors,
            date: date,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private var parsedAmount: Double? {
        guard let value = Double(amount), value > 0 else { return nil }
        return value
    }

    @ViewBuilder
    private func inputCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.headline)
                content()
            }
        }
    }

    private func validationText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.red)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(FinanceStore())
    }
}
