//
//  FinanceStore.swift
//  ExpenseTracker
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class FinanceStore: ObservableObject {
    @Published var transactions: [TransactionItem] = []
    @Published var selectedMonth: Date = .now
    @Published var appearance: AppAppearance = .system

    private let storageURL: URL
    private let appearanceKey = "finance.app.appearance"

    init() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL.documentsDirectory
        storageURL = documentsURL.appendingPathComponent("transactions.json")
        load()
    }

    var categories: [FinanceCategory] {
        let custom = Dictionary(grouping: transactions.filter { $0.categoryID == nil }, by: \.categoryTitle)
            .compactMap { _, items -> FinanceCategory? in
                guard let latest = items.sorted(by: { $0.date > $1.date }).first else { return nil }
                return FinanceCategory(
                    id: "custom-\(latest.categoryTitle.lowercased())",
                    title: latest.categoryTitle,
                    symbol: latest.categorySymbol,
                    colors: latest.categoryColors
                )
            }

        return FinanceCategory.defaults + custom.sorted { $0.title < $1.title }
    }

    var currentMonthTransactions: [TransactionItem] {
        transactions
            .filter { Calendar.current.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
            .sorted { $0.date > $1.date }
    }

    var monthlySnapshot: MonthlySnapshot {
        let income = currentMonthTransactions
            .filter { $0.kind == .income }
            .reduce(0) { $0 + $1.amount }
        let expenses = currentMonthTransactions
            .filter { $0.kind == .expense }
            .reduce(0) { $0 + $1.amount }

        return MonthlySnapshot(income: income, expenses: expenses)
    }

    var recentTransactions: [TransactionItem] {
        Array(transactions.sorted { $0.date > $1.date }.prefix(8))
    }

    var hasTransactions: Bool {
        !transactions.isEmpty
    }

    func transactions(for kind: TransactionKind? = nil) -> [TransactionItem] {
        let base = currentMonthTransactions
        guard let kind else { return base }
        return base.filter { $0.kind == kind }
    }

    func addTransaction(_ item: TransactionItem) {
        transactions.append(item)
        save()
    }

    func deleteTransactions(at offsets: IndexSet, in items: [TransactionItem]) {
        let ids = offsets.map { items[$0].id }
        transactions.removeAll { ids.contains($0.id) }
        save()
    }

    func monthlyTotalsByCategory(kind: TransactionKind) -> [(category: String, total: Double, colors: [String], symbol: String)] {
        let grouped = Dictionary(grouping: currentMonthTransactions.filter { $0.kind == kind }, by: \.categoryTitle)

        return grouped.compactMap { key, items in
            guard let latest = items.first else { return nil }
            return (
                category: key,
                total: items.reduce(0) { $0 + $1.amount },
                colors: latest.categoryColors,
                symbol: latest.categorySymbol
            )
        }
        .sorted { $0.total > $1.total }
    }

    func formattedCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSNumber) ?? "$0"
    }

    private func load() {
        if let rawAppearance = UserDefaults.standard.string(forKey: appearanceKey),
           let appearance = AppAppearance(rawValue: rawAppearance) {
            self.appearance = appearance
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? decoder.decode([TransactionItem].self, from: data) else {
            transactions = []
            return
        }

        if Self.isLegacySeedData(decoded) {
            transactions = []
            save()
        } else {
            transactions = decoded
        }
    }

    func setAppearance(_ appearance: AppAppearance) {
        self.appearance = appearance
        UserDefaults.standard.set(appearance.rawValue, forKey: appearanceKey)
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(transactions) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
    private static func isLegacySeedData(_ items: [TransactionItem]) -> Bool {
        guard items.count == 5 else { return false }

        let signatures = Set(items.map {
            "\($0.kind.rawValue)|\($0.categoryTitle)|\($0.note)|\($0.amount)"
        })

        let legacy = Set([
            "income|Salary|April payroll|4200.0",
            "expense|Food|Dinner with friends|92.0",
            "expense|Travel|Airport transfer|260.0",
            "expense|Bills|Internet|145.0",
            "income|Side Project|Design sprint|480.0"
        ])

        return signatures == legacy
    }
}
