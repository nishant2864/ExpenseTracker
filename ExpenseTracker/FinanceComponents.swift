//
//  FinanceComponents.swift
//  ExpenseTracker
//

import Charts
import SwiftUI

struct AppBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            // Base gradient — dark: deep ocean navy / light: existing warm teal
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(hex: "0D1B2A") ?? .black,
                        Color(hex: "1A3A4A") ?? .black,
                        Color(hex: "0A2030") ?? .black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Ambient glow blobs (dark mode only)
                Circle()
                    .fill(Color(hex: "4F8EF7")?.opacity(0.18) ?? .clear)
                    .frame(width: 340)
                    .blur(radius: 100)
                    .offset(x: -80, y: -200)
                    .opacity(glowOpacity)

                Circle()
                    .fill(Color(hex: "2EC4B6")?.opacity(0.14) ?? .clear)
                    .frame(width: 280)
                    .blur(radius: 80)
                    .offset(x: 120, y: 260)
                    .opacity(glowOpacity)
            } else {
                LinearGradient(
                    colors: [Color(hex: "EBF4F6") ?? .white, Color(hex: "7AB2B2") ?? .teal],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .ignoresSafeArea()

                // Subtle light-mode glow blobs
                Circle()
                    .fill(Color(red: 0.29, green: 0.39, blue: 0.53).opacity(0.08))
                    .frame(width: 240)
                    .blur(radius: 90)
                    .offset(x: -120, y: -250)

                Circle()
                    .fill(Color(red: 0.45, green: 0.52, blue: 0.64).opacity(0.06))
                    .frame(width: 280)
                    .blur(radius: 100)
                    .offset(x: 160, y: 220)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).delay(0.3)) {
                glowOpacity = 1
            }
        }
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

// MARK: - ATM Card / Balance Card

struct ATMCardView: View {
    let snapshot: MonthlySnapshot
    let namespace: Namespace.ID
    @EnvironmentObject private var store: FinanceStore

    @State private var isFlipped = false
    @State private var cardAppeared = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                if store.cardGenerated {
                    CardFrontFace()
                        .opacity(isFlipped ? 0 : 1)
                        .rotation3DEffect(
                            .degrees(isFlipped ? 180 : 0),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.4
                        )

                    CardBackFace(snapshot: snapshot)
                        .opacity(isFlipped ? 1 : 0)
                        .rotation3DEffect(
                            .degrees(isFlipped ? 360 : 180),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.4
                        )
                } else {
                    PlaceholderBalanceCard(snapshot: snapshot)
                }
            }
            .frame(height: 200)
            .scaleEffect(cardAppeared ? 1 : 0.88)
            .opacity(cardAppeared ? 1 : 0)
            .onTapGesture {
                guard store.cardGenerated else { return }
                withAnimation(.spring(duration: 0.6, bounce: 0.2)) { isFlipped.toggle() }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            .onAppear {
                withAnimation(.spring(duration: 0.55, bounce: 0.25).delay(0.1)) { cardAppeared = true }
            }

            if store.cardGenerated {
                HStack(spacing: 5) {
                    Image(systemName: "hand.tap.fill").font(.caption2)
                    Text("Tap to \(isFlipped ? "see card" : "see balance")").font(.caption)
                }
                .foregroundStyle(.secondary)
                .transition(.opacity)
            } else {
                Text("Generate your card in Profile")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Placeholder Balance Card (glass, shown before card generated)

struct PlaceholderBalanceCard: View {
    let snapshot: MonthlySnapshot
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)

            VStack(alignment: .leading, spacing: 0) {
                // Balance
                VStack(alignment: .leading, spacing: 4) {
                    Text("AVAILABLE BALANCE")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .kerning(1.4)
                    Text(store.formattedCurrency(snapshot.balance))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.horizontal, .top], 20)

                Spacer()

                Divider().padding(.horizontal, 20)

                // Income / Expenses
                HStack(spacing: 0) {
                    balanceStat(label: "INCOME",
                                value: store.formattedCurrency(snapshot.income),
                                tint: Color(hex: "2EC4B6") ?? .green)
                    Spacer()
                    Rectangle().fill(.white.opacity(0.2)).frame(width: 1, height: 32)
                    Spacer()
                    balanceStat(label: "EXPENSES",
                                value: store.formattedCurrency(snapshot.expenses),
                                tint: Color(hex: "FF6B6B") ?? .red,
                                trailing: true)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
    }

    private func balanceStat(label: String, value: String, tint: Color, trailing: Bool = false) -> some View {
        VStack(alignment: trailing ? .trailing : .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.secondary)
                .kerning(1.2)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
        }
    }
}

// MARK: - Card Front (User Details)

private struct CardFrontFace: View {
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        ZStack {
            cardBackground

            // Three-zone layout: logo | chip+number | name+expiry
            VStack(alignment: .leading, spacing: 0) {

                // ZONE 1 — Logo row
                HStack(alignment: .center) {
                    HStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        Text("Expense\nDaily")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineSpacing(1)
                    }
                    Spacer()
                    Text("ACTIVE")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(.green.opacity(0.75))
                        .kerning(1.8)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.15), in: Capsule())
                }

                Spacer() // pushes chip down to natural mid-point

                // ZONE 2 — Chip + card number
                VStack(alignment: .leading, spacing: 10) {
                    // EMV Chip
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "D4AF37") ?? .yellow, Color(hex: "AA8C2C") ?? .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 30)
                        .overlay(
                            VStack(spacing: 5) {
                                ForEach(0..<3, id: \.self) { _ in
                                    Rectangle()
                                        .fill(.black.opacity(0.15))
                                        .frame(height: 0.8)
                                }
                            }
                            .padding(.horizontal, 4)
                        )

                    // Card number
                    Text(store.cardGenerated ? maskedNumber : "•••• •••• •••• ••••")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(store.cardGenerated ? 1 : 0.45))
                        .kerning(1)
                }

                Spacer(minLength: 12) // flexible but at least 12pt above bottom row

                // ZONE 3 — Cardholder name + expiry + contactless
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CARDHOLDER")
                            .font(.system(size: 7, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                            .kerning(0.8)
                        Text(store.cardGenerated ? store.userDisplayName.uppercased() : "YOUR NAME")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("VALID THRU")
                            .font(.system(size: 7, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                            .kerning(0.8)
                        Text(store.cardGenerated ? store.cardExpiry : "MM/YY")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }

                    Image(systemName: "wave.3.right")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(.white.opacity(0.65))
                        .padding(.leading, 8)
                }
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
    }

    private var maskedNumber: String {
        let parts = store.cardNumber.components(separatedBy: " ")
        guard parts.count == 4 else { return "•••• •••• •••• ••••" }
        return "\(parts[0]) \(parts[1]) •••• \(parts[3])"
    }

    private var cardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "1A1A2E") ?? .black,
                    Color(hex: "16213E") ?? .black,
                    Color(hex: "0F3460") ?? .blue
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(RadialGradient(
                    colors: [Color(hex: "4F8EF7")?.opacity(0.35) ?? .clear, .clear],
                    center: .center, startRadius: 0, endRadius: 160
                ))
                .frame(width: 320)
                .offset(x: 80, y: -60)
            Circle()
                .fill(RadialGradient(
                    colors: [Color(hex: "6E44C8")?.opacity(0.28) ?? .clear, .clear],
                    center: .center, startRadius: 0, endRadius: 130
                ))
                .frame(width: 260)
                .offset(x: -100, y: 90)
        }
    }
}

// MARK: - Card Back (Balance Data)

private struct CardBackFace: View {
    let snapshot: MonthlySnapshot
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "0F3460") ?? .blue,
                    Color(hex: "16213E") ?? .black,
                    Color(hex: "1A1A2E") ?? .black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Shimmer accents
            Circle()
                .fill(RadialGradient(
                    colors: [Color(hex: "2EC4B6")?.opacity(0.28) ?? .clear, .clear],
                    center: .center, startRadius: 0, endRadius: 140
                ))
                .frame(width: 280)
                .offset(x: -90, y: -40)
            Circle()
                .fill(RadialGradient(
                    colors: [Color(hex: "4F8EF7")?.opacity(0.18) ?? .clear, .clear],
                    center: .center, startRadius: 0, endRadius: 120
                ))
                .frame(width: 240)
                .offset(x: 110, y: 80)

            // Content arranged in a clean VStack — no fixed position hacks
            VStack(alignment: .leading, spacing: 0) {

                // Magnetic stripe at very top
                Rectangle()
                    .fill(.black.opacity(0.85))
                    .frame(height: 38)

                Spacer() // push balance into vertical centre

                // Balance zone
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AVAILABLE BALANCE")
                            .font(.system(size: 7.5, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.55))
                            .kerning(1.4)
                        Text(store.formattedCurrency(snapshot.balance))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                    }
                    Spacer()
                    Circle()
                        .fill(snapshot.balance >= 0
                              ? Color(hex: "2EC4B6") ?? .green
                              : Color(hex: "FF6B6B") ?? .red)
                        .frame(width: 10, height: 10)
                        .shadow(
                            color: (snapshot.balance >= 0
                                    ? Color(hex: "2EC4B6") ?? .green
                                    : Color(hex: "FF6B6B") ?? .red).opacity(0.6),
                            radius: 6
                        )
                }
                .padding(.horizontal, 20)

                Spacer()

                Divider()
                    .background(.white.opacity(0.15))
                    .padding(.horizontal, 20)

                // Income / Expenses
                HStack(spacing: 0) {
                    statCol(label: "INCOME",
                            value: store.formattedCurrency(snapshot.income),
                            tint: Color(hex: "2EC4B6") ?? .green)
                    Spacer()
                    Rectangle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 1, height: 32)
                    Spacer()
                    statCol(label: "EXPENSES",
                            value: store.formattedCurrency(snapshot.expenses),
                            tint: Color(hex: "FF6B6B") ?? .red,
                            trailing: true)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                Divider()
                    .background(.white.opacity(0.15))
                    .padding(.horizontal, 20)

                // Card footer: last 4 + wave
                HStack {
                    Text("•••• •••• •••• \(store.cardLast4)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
    }

    private func statCol(label: String, value: String, tint: Color, trailing: Bool = false) -> some View {
        VStack(alignment: trailing ? .trailing : .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 7.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
                .kerning(1.2)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
        }
    }
}


struct QuickStatsRow: View {
    let snapshot: MonthlySnapshot
    var onIncomeTap: (() -> Void)? = nil
    var onExpenseTap: (() -> Void)? = nil
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Income",
                value: store.formattedCurrency(snapshot.income),
                systemImage: "arrow.down.left.circle.fill",
                tint: .green,
                onTap: onIncomeTap
            )
            StatCard(
                title: "Expenses",
                value: store.formattedCurrency(snapshot.expenses),
                systemImage: "arrow.up.right.circle.fill",
                tint: .red,
                onTap: onExpenseTap
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
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
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
}

struct SpendingChartCard: View {
    let items: [(category: String, total: Double, colors: [String], symbol: String)]
    let formatter: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("This month’s spending")
                .font(.title3.bold())
                    .padding(.top, 20)

            if items.isEmpty {
                EmptyStateCard(
                    title: "No spending yet",
                    subtitle: "Your category graph appears here as soon as you log expenses.",
                    systemImage: "chart.bar.xaxis"
                )
            } else {
                GlassCard {
                    VStack(alignment: .leading, spacing: 24) {
                        Spacer()
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
                        .frame(height: 180)
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }

                        VStack(spacing: 0) {
                            let topItems = Array(items.prefix(3))
                            ForEach(0..<topItems.count, id: \.self) { index in
                                let item = topItems[index]
                                HStack(spacing: 12) {
                                    CategoryIcon(symbol: item.symbol, colors: item.colors)
                                    Text(item.category)
                                        .font(.body.weight(.medium))
                                    Spacer()
                                    Text(formatter(item.total))
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 14)
                                
                                if index < topItems.count - 1 {
                                    Divider().padding(.leading, 44)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.bottom, 30)
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
                VStack(alignment: .center, spacing: 18) {
                    Spacer()
                    
                    Image(systemName: "creditcard.and.123")
                        .font(.system(size: 35, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("Start with your first transaction")
                        .font(.system(.title2, weight: .bold))
                    
                    Text("You won’t see balances, charts, or summaries until you add real activity. Begin with one income or one expense and the app will build the month around your actual data.")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("No mock numbers", systemImage: "checkmark.circle")
                    Label("Clear monthly overview", systemImage: "checkmark.circle")
                    Label("Insights only after real usage", systemImage: "checkmark.circle")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                
                Spacer()

                Button(action: action) {
                    Text("Add first transaction")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            Capsule()
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
        }
    }

    private func shiftMonth(by amount: Int) {
        selectedMonth = Calendar.current.date(byAdding: .month, value: amount, to: selectedMonth) ?? selectedMonth
    }
}

struct ProfileHeaderCard: View {
    @EnvironmentObject private var store: FinanceStore

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
                    Text(store.userFirstName.prefix(1).uppercased().isEmpty ? "?" : String(store.userFirstName.prefix(1).uppercased()))
                        .font(.title.bold())
                        .foregroundStyle(.black.opacity(0.8))
                }
                .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 6) {
                    Text(store.userDisplayName)
                        .font(.title3.bold())
                    if !store.userEmail.isEmpty {
                        Text(store.userEmail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if !store.userPhone.isEmpty {
                        Text(store.userPhone)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Finance Manager")
                            .foregroundStyle(.secondary)
                    }
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
