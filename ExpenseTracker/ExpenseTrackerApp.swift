//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  Created by NISHANT BHARDWAJ on 06/04/26.
//

import SwiftUI

@main
struct ExpenseTrackerApp: App {
    @StateObject private var store = FinanceStore()

    var body: some Scene {
        WindowGroup {
            RootCoordinator()
                .environmentObject(store)
        }
    }
}
