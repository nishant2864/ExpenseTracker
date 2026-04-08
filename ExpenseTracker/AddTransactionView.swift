import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    var onSaveComplete: (() -> Void)? = nil

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
            .scrollIndicators(.hidden)
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
                .font(.system(.largeTitle, weight: .bold))
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
            onSaveComplete?()
        } label: {
            Text("Save transaction")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
