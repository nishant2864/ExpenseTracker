//
//  FinanceStore.swift
//  ExpenseTracker
//

import Combine
import Foundation
import SwiftUI
import UIKit

@MainActor
final class FinanceStore: ObservableObject {
    @Published var transactions: [TransactionItem] = []
    @Published var selectedMonth: Date = .now
    @Published var appearance: AppAppearance = .system

    // User profile
    @Published var userFirstName: String = ""
    @Published var userLastName: String = ""
    @Published var userEmail: String = ""
    @Published var userPhone: String = ""
    @Published var profileImageData: Data? = nil

    // Onboarding state
    @Published var hasCompletedOnboarding: Bool = false
    @Published var showingFirstTransactionSheet: Bool = false

    // Card
    @Published var cardNumber: String = ""
    @Published var cardGenerated: Bool = false

    private let storageURL: URL
    private let appearanceKey = "finance.app.appearance"
    private let onboardingKey = "finance.app.onboardingDone"
    private let userNameKey = "finance.app.userName"
    private let userContactKey = "finance.app.userContact"
    private let cardKey = "finance.app.card"
    private let profileImageKey = "finance.app.profileImage"

    init() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL.documentsDirectory
        storageURL = documentsURL.appendingPathComponent("transactions.json")
        load()
    }

    // MARK: - User Profile

    var userDisplayName: String {
        let full = [userFirstName, userLastName].filter { !$0.isEmpty }.joined(separator: " ")
        return full.isEmpty ? "Friend" : full
    }

    func saveUserName(first: String, last: String) {
        userFirstName = first
        userLastName = last
        var dict = UserDefaults.standard.dictionary(forKey: userNameKey) ?? [:]
        dict["first"] = first
        dict["last"] = last
        UserDefaults.standard.set(dict, forKey: userNameKey)
    }

    func saveContactInfo(email: String, phone: String) {
        userEmail = email
        userPhone = phone
        var dict = UserDefaults.standard.dictionary(forKey: userContactKey) ?? [:]
        dict["email"] = email
        dict["phone"] = phone
        UserDefaults.standard.set(dict, forKey: userContactKey)
    }

    func saveProfileImage(_ data: Data?) {
        profileImageData = data
        if let data {
            UserDefaults.standard.set(data, forKey: profileImageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: profileImageKey)
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    func generateCard() {
        guard !cardGenerated else { return }
        let digits = (0..<16).map { _ in String(Int.random(in: 0...9)) }.joined()
        let groups = stride(from: 0, to: 16, by: 4).map {
            String(digits[digits.index(digits.startIndex, offsetBy: $0)..<digits.index(digits.startIndex, offsetBy: $0 + 4)])
        }
        cardNumber = groups.joined(separator: " ")
        cardGenerated = true
        let dict: [String: Any] = ["number": cardNumber, "generated": true]
        UserDefaults.standard.set(dict, forKey: cardKey)
    }

    func destroyCard() {
        cardNumber = ""
        cardGenerated = false
        UserDefaults.standard.removeObject(forKey: cardKey)
    }

    /// Last 4 digits of the card number
    var cardLast4: String {
        cardGenerated ? String(cardNumber.replacingOccurrences(of: " ", with: "").suffix(4)) : "••••"
    }

    /// Card expiry — 3 years from account creation, stored as month/year
    var cardExpiry: String {
        let target = Calendar.current.date(byAdding: .year, value: 3, to: .now) ?? .now
        return target.formatted(.dateTime.month(.twoDigits).year(.twoDigits))
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

        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)

        if let nameDict = UserDefaults.standard.dictionary(forKey: userNameKey) {
            userFirstName = nameDict["first"] as? String ?? ""
            userLastName = nameDict["last"] as? String ?? ""
        }
        if let contactDict = UserDefaults.standard.dictionary(forKey: userContactKey) {
            userEmail = contactDict["email"] as? String ?? ""
            userPhone = contactDict["phone"] as? String ?? ""
        }
        profileImageData = UserDefaults.standard.data(forKey: profileImageKey)
        if let cardDict = UserDefaults.standard.dictionary(forKey: cardKey) {
            cardNumber = cardDict["number"] as? String ?? ""
            cardGenerated = cardDict["generated"] as? Bool ?? false
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
