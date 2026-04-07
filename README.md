# ExpenseTracker

ExpenseTracker is an iOS SwiftUI finance manager built with a native Apple-first feel: gradient balance surfaces, glass cards, animated summaries, category tracking, and persistent local storage for monthly budgeting.

## Features

- Add income and expenses with validation
- Track spending by category with predefined and custom categories
- Monthly summary for income, expenses, and remaining balance
- Bottom tab navigation for Home, Transactions, Insights, and Profile
- Light, dark, and system appearance modes
- Apple-style motion, charts, and glass surfaces where supported
- Local JSON persistence in the app documents directory

## Tech

- SwiftUI
- Charts
- Observation
- Local file storage using `JSONEncoder` / `JSONDecoder`

## Run

1. Open `ExpenseTracker.xcodeproj` in Xcode 26 or newer.
2. Select an iPhone simulator running iOS 26.0 or later for full glass styling support.
3. Build and run the `ExpenseTracker` scheme.

## Structure

- `ExpenseTracker/ExpenseTrackerApp.swift`: app entry and shared store
- `ExpenseTracker/FinanceModels.swift`: models, categories, and appearance types
- `ExpenseTracker/FinanceStore.swift`: persistence, monthly aggregation, and state
- `ExpenseTracker/ContentView.swift`: tab shell and screen composition
- `ExpenseTracker/FinanceComponents.swift`: reusable UI surfaces and cards

## Notes

- The app seeds sample data on first launch so the UI is populated immediately.
- The `glassEffect(_:in:)` modifier is conditionally applied on supported OS versions.
- Screenshots and release artifacts can be added after building from Xcode or App Store Connect/TestFlight export flows.
