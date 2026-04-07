//
//  FinanceModels.swift
//  ExpenseTracker
//

import Foundation
import SwiftUI

enum TransactionKind: String, Codable, CaseIterable, Identifiable {
    case income
    case expense

    var id: String { rawValue }

    var title: String {
        switch self {
        case .income: "Income"
        case .expense: "Expense"
        }
    }

    var tint: Color {
        switch self {
        case .income: .green
        case .expense: .red
        }
    }

    var multiplier: Double {
        switch self {
        case .income: 1
        case .expense: -1
        }
    }
}

struct FinanceCategory: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let symbol: String
    let colors: [String]

    var gradient: LinearGradient {
        LinearGradient(
            colors: colors.compactMap(Color.init(hex:)),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let defaults: [FinanceCategory] = [
        .init(id: "food", title: "Food", symbol: "fork.knife", colors: ["#86A89C", "#4F6B63"]),
        .init(id: "travel", title: "Travel", symbol: "airplane", colors: ["#7D95B8", "#4D6387"]),
        .init(id: "shopping", title: "Shopping", symbol: "bag", colors: ["#AE93A9", "#765C77"]),
        .init(id: "salary", title: "Salary", symbol: "banknote", colors: ["#8FAE8A", "#557253"]),
        .init(id: "freelance", title: "Freelance", symbol: "laptopcomputer", colors: ["#C4A780", "#8B6B49"]),
        .init(id: "bills", title: "Bills", symbol: "bolt.fill", colors: ["#B88C7D", "#7E584A"]),
        .init(id: "health", title: "Health", symbol: "cross.case.fill", colors: ["#7CA0A8", "#4E6970"]),
        .init(id: "savings", title: "Savings", symbol: "lock.shield.fill", colors: ["#8F97BB", "#5D648B"])
    ]

    static let customPalette: [[String]] = [
        ["#8A9CB4", "#586B84"],
        ["#B8A289", "#7A6450"],
        ["#94A892", "#627360"],
        ["#A88B97", "#745D67"]
    ]
}

struct TransactionItem: Identifiable, Codable, Hashable {
    let id: UUID
    var kind: TransactionKind
    var amount: Double
    var categoryID: String?
    var categoryTitle: String
    var categorySymbol: String
    var categoryColors: [String]
    var date: Date
    var note: String

    init(
        id: UUID = UUID(),
        kind: TransactionKind,
        amount: Double,
        categoryID: String?,
        categoryTitle: String,
        categorySymbol: String,
        categoryColors: [String],
        date: Date,
        note: String
    ) {
        self.id = id
        self.kind = kind
        self.amount = amount
        self.categoryID = categoryID
        self.categoryTitle = categoryTitle
        self.categorySymbol = categorySymbol
        self.categoryColors = categoryColors
        self.date = date
        self.note = note
    }

    var signedAmount: Double {
        amount * kind.multiplier
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: categoryColors.compactMap(Color.init(hex:)),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct MonthlySnapshot {
    let income: Double
    let expenses: Double

    var balance: Double { income - expenses }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

extension Color {
    nonisolated init?(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else { return nil }

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        self.init(red: red, green: green, blue: blue)
    }
}
