//
//  FinanceComponents.swift
//  ExpenseTracker
//

import Charts
import SwiftUI

struct AppBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .bottom,
                endPoint: .top
            )

            Circle()
                .fill(Color(red: 0.29, green: 0.39, blue: 0.53).opacity(colorScheme == .dark ? 0.20 : 0.08))
                .frame(width: 240)
                .blur(radius: 90)
                .offset(x: -120, y: -250)

            Circle()
                .fill(Color(red: 0.45, green: 0.52, blue: 0.64).opacity(colorScheme == .dark ? 0.14 : 0.06))
                .frame(width: 280)
                .blur(radius: 100)
                .offset(x: 160, y: 220)
        }
    }

    private var backgroundColors: [Color] {
        colorScheme == .dark
            ? [Color(hex: "09637E") ?? .black, Color(hex: "088395") ?? .teal]
            : [Color(hex: "EBF4F6") ?? .white, Color(hex: "7AB2B2") ?? .teal]
    }
}

struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .modifier(GlassSurfaceModifier())
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 20, y: 10)
    }
}

struct BalanceHeroCard: View {
    let snapshot: MonthlySnapshot
    let namespace: Namespace.ID
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.82, green: 0.87, blue: 0.94),
                            Color(red: 0.68, green: 0.77, blue: 0.89),
                            Color(red: 0.56, green: 0.65, blue: 0.80)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .matchedGeometryEffect(id: "balance-card", in: namespace)
                .frame(height: 250)

            VStack(alignment: .leading, spacing: 12) {
                Text("Available balance")
                    .font(.headline)
                    .foregroundStyle(.black.opacity(0.65))

                Text(store.formattedCurrency(snapshot.balance))
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.black)
                    .contentTransition(.numericText())

                Text("Income \(store.formattedCurrency(snapshot.income)) • Expenses \(store.formattedCurrency(snapshot.expenses))")
                    .foregroundStyle(.black.opacity(0.7))

                Spacer()

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Healthy pacing")
                            .font(.headline)
                            .foregroundStyle(.black)
                        Text("Your month stays on track when spending remains below income.")
                            .font(.subheadline)
                            .foregroundStyle(.black.opacity(0.65))
                    }

                    Spacer()

                    Image(systemName: "waveform.path.ecg.rectangle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.black.opacity(0.75))
                        .symbolEffect(.pulse)
                }
            }
            .padding(24)
        }
    }
}

struct QuickStatsRow: View {
    let snapshot: MonthlySnapshot
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Income",
                value: store.formattedCurrency(snapshot.income),
                systemImage: "arrow.down.left.circle.fill",
                tint: .green
            )
            StatCard(
                title: "Expenses",
                value: store.formattedCurrency(snapshot.expenses),
                systemImage: "arrow.up.right.circle.fill",
                tint: .red
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(tint)
                Text(title)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.bold())
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct SpendingChartCard: View {
    let items: [(category: String, total: Double, colors: [String], symbol: String)]
    let formatter: (Double) -> String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                Text("This month’s spending")
                    .font(.title3.bold())

                if items.isEmpty {
                    EmptyStateCard(
                        title: "No spending yet",
                        subtitle: "Your category graph appears here as soon as you log expenses.",
                        systemImage: "chart.bar.xaxis"
                    )
                } else {
                    Chart(items, id: \.category) { item in
                        BarMark(
                            x: .value("Category", item.category),
                            y: .value("Amount", item.total)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .foregroundStyle(
                            LinearGradient(
                                colors: item.colors.compactMap(Color.init(hex:)),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .frame(height: 190)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }

                    ForEach(items.prefix(3), id: \.category) { item in
                        HStack {
                            CategoryIcon(symbol: item.symbol, colors: item.colors)
                            Text(item.category)
                            Spacer()
                            Text(formatter(item.total))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

struct SummaryRingCard: View {
    let snapshot: MonthlySnapshot
    let formatter: (Double) -> String
    let animationTrigger: Int
    @State private var animatedIncome = 0.0
    @State private var animatedExpenses = 0.0

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                Text("Monthly summary")
                    .font(.title3.bold())

                Chart {
                    SectorMark(
                        angle: .value("Income", max(animatedIncome, 1)),
                        innerRadius: .ratio(0.62),
                        angularInset: 2
                    )
                    .foregroundStyle(Color(red: 0.54, green: 0.69, blue: 0.56).gradient)

                    SectorMark(
                        angle: .value("Expenses", max(animatedExpenses, 1)),
                        innerRadius: .ratio(0.62),
                        angularInset: 2
                    )
                    .foregroundStyle(Color(red: 0.71, green: 0.52, blue: 0.47).gradient)
                }
                .chartLegend(.hidden)
                .frame(height: 240)
                .overlay {
                    VStack(spacing: 6) {
                        Text("Balance")
                            .foregroundStyle(.secondary)
                        Text(formatter(snapshot.balance))
                            .font(.title.bold())
                            .contentTransition(.numericText())
                    }
                }

                HStack {
                    LegendRow(title: "Income", value: formatter(snapshot.income), tint: Color(red: 0.54, green: 0.69, blue: 0.56))
                    Spacer()
                    LegendRow(title: "Expenses", value: formatter(snapshot.expenses), tint: Color(red: 0.71, green: 0.52, blue: 0.47))
                }
            }
        }
        .onAppear(perform: animateChart)
        .onChange(of: animationTrigger) { _, _ in
            animateChart()
        }
    }

    private func animateChart() {
        animatedIncome = 0
        animatedExpenses = 0
        withAnimation(.spring(duration: 0.9, bounce: 0.18)) {
            animatedIncome = snapshot.income
            animatedExpenses = snapshot.expenses
        }
    }
}

struct CategoryBreakdownCard: View {
    let title: String
    let items: [(category: String, total: Double, colors: [String], symbol: String)]
    let formatter: (Double) -> String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.title3.bold())

                if items.isEmpty {
                    EmptyStateCard(
                        title: "Nothing to show yet",
                        subtitle: "The breakdown fills in automatically once this month has activity.",
                        systemImage: "circle.dotted"
                    )
                } else {
                    ForEach(items, id: \.category) { item in
                        HStack(spacing: 12) {
                            CategoryIcon(symbol: item.symbol, colors: item.colors)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.category)
                                GeometryReader { proxy in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(.white.opacity(0.08))
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: item.colors.compactMap(Color.init(hex:)),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: proxy.size.width * normalizedWidth(for: item.total, within: items))
                                    }
                                }
                                .frame(height: 8)
                            }

                            Spacer()

                            Text(formatter(item.total))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func normalizedWidth(for value: Double, within items: [(category: String, total: Double, colors: [String], symbol: String)]) -> CGFloat {
        guard let maximum = items.map(\.total).max(), maximum > 0 else { return 0 }
        return Swift.max(0.18, value / maximum)
    }
}

struct TransactionRow: View {
    let item: TransactionItem
    let formattedAmount: String

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                CategoryIcon(symbol: item.categorySymbol, colors: item.categoryColors)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.categoryTitle)
                        .font(.headline)
                    Text(item.note.isEmpty ? "No note" : item.note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(item.kind == .income ? "+" : "-")\(formattedAmount)")
                        .font(.headline)
                        .foregroundStyle(item.kind == .income ? .green : .primary)
                    Text(item.date.formatted(.dateTime.day().month().hour().minute()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct EmptyStateCard: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct FirstRunHomeCard: View {
    let action: () -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text("Start with your first transaction")
                    .font(.system(.title2, weight: .bold))

                Text("You won’t see balances, charts, or summaries until you add real activity. Begin with one income or one expense and the app will build the month around your actual data.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    Label("No mock numbers", systemImage: "checkmark.circle")
                    Label("Clear monthly overview", systemImage: "checkmark.circle")
                    Label("Insights only after real usage", systemImage: "checkmark.circle")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Button(action: action) {
                    Text("Add first transaction")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.accentColor)
                        )
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct CategoryChip: View {
    let category: FinanceCategory
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            CategoryIcon(symbol: category.symbol, colors: category.colors)
            Text(category.title)
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(isSelected ? .white.opacity(0.6) : .clear, lineWidth: 1.5)
        )
        .scaleEffect(isSelected ? 1 : 0.98)
    }
}

struct CategoryIcon: View {
    let symbol: String
    let colors: [String]

    var body: some View {
        Image(systemName: symbol)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(width: 42, height: 42)
            .background(
                LinearGradient(
                    colors: colors.compactMap(Color.init(hex:)),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
    }
}

struct AddTransactionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(Color.accentColor)
                .frame(width: 62, height: 62)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.12), lineWidth: 1))
                .shadow(color: .black.opacity(0.18), radius: 24, y: 8)
        }
        .buttonStyle(.plain)
    }
}

struct MonthPicker: View {
    @Binding var selectedMonth: Date

    var body: some View {
        Menu {
            Button("Previous Month") {
                shiftMonth(by: -1)
            }
            Button("Next Month") {
                shiftMonth(by: 1)
            }
            Button("Current Month") {
                selectedMonth = .now
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                Text(selectedMonth.formatted(.dateTime.month(.abbreviated)))
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
        }
    }

    private func shiftMonth(by amount: Int) {
        selectedMonth = Calendar.current.date(byAdding: .month, value: amount, to: selectedMonth) ?? selectedMonth
    }
}

struct ProfileHeaderCard: View {
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.65, green: 0.94, blue: 0.82), Color(red: 0.5, green: 0.67, blue: 1.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "person.fill")
                        .font(.title)
                        .foregroundStyle(.black.opacity(0.8))
                }
                .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Alex")
                        .font(.title3.bold())
                    Text("Finance Manager")
                        .foregroundStyle(.secondary)
                    Text("Stay intentional with every transaction.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }
}

struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct LegendRow: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tint)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
            }
        }
    }
}

private struct GlassSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        } else {
            content
        }
    }
}
