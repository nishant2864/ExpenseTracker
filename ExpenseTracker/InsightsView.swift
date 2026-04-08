import SwiftUI

struct InsightsView: View {
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
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background(AppBackdrop().ignoresSafeArea())
        .navigationTitle("Insights")
        .onAppear {
            animationTrigger += 1
        }
    }
}
