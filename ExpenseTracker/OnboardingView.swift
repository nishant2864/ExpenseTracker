import SwiftUI

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let imageName: String
    let gradientColors: [Color]
    let title: String
    let subtitle: String
}

private let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        imageName: "HomeTab",
        gradientColors: [Color(hex: "4F8EF7") ?? .blue, Color(hex: "2D5BA3") ?? .blue],
        title: "Know Where Your Money Goes",
        subtitle: "Track every rupee with smart categories. See exactly what you spend on food, travel, bills, and more — all in one clean dashboard."
    ),
    OnboardingPage(
        imageName: "AddTransactionsScreen",
        gradientColors: [Color(hex: "6E44C8") ?? .purple, Color(hex: "9B59B6") ?? .purple],
        title: "Log Income & Expenses Instantly",
        subtitle: "Add transactions in seconds. Whether it's a salary deposit or a coffee run, every entry builds a clearer picture of your finances."
    ),
    OnboardingPage(
        imageName: "InsightsTab",
        gradientColors: [Color(hex: "2EC4B6") ?? .teal, Color(hex: "1A8F85") ?? .teal],
        title: "Insights That Actually Helps",
        subtitle: "Monthly summaries, spending rings, and category charts so you always know if this month is healthy — before it ends."
    )
]

// MARK: - Onboarding View

struct OnboardingView: View {
    @State private var currentPage = 0
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            AppBackdrop().ignoresSafeArea()

            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<onboardingPages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.accentColor : Color.secondary.opacity(0.35))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(duration: 0.4), value: currentPage)
                    }
                    Spacer()

                    if currentPage < onboardingPages.count - 1 {
                        Button("Skip") {
                            withAnimation(.spring(duration: 0.45)) {
                                currentPage = onboardingPages.count - 1
                            }
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)

                // Pages
                TabView(selection: $currentPage) {
                    ForEach(Array(onboardingPages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(duration: 0.45), value: currentPage)

                // CTA
                VStack(spacing: 14) {
                    if currentPage < onboardingPages.count - 1 {
                        PrimaryButton(title: "Next") {
                            withAnimation(.spring(duration: 0.45)) {
                                currentPage += 1
                            }
                        }
                    } else {
                        PrimaryButton(title: "Get Started") {
                            onFinish()
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.gradientColors.map { $0.opacity(0.22) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)

                Image(page.imageName)
                    .resizable()
                    .scaledToFit()
            }
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(duration: 0.7, bounce: 0.3).delay(0.1), value: appeared)

            Spacer().frame(height: 44)

            // Text
            VStack(spacing: 14) {
                Text(page.title)
                    .font(.system(.title, weight: .bold))
                    .multilineTextAlignment(.center)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.6).delay(0.2), value: appeared)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.6).delay(0.3), value: appeared)


            }
            .padding(.horizontal, 28)

            Spacer()
        }
        .onAppear { appeared = true }
        .onDisappear { appeared = false }
    }
}


// MARK: - User Setup Flow

enum SetupStep {
    case name
    case contact
    case firstTransaction
    case cardSetup
}

struct UserSetupView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var step: SetupStep = .name
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var showValidation = false
    @FocusState private var focus: SetupField?
    @Namespace private var stepNamespace

    let onFinish: () -> Void

    private enum SetupField: Hashable {
        case firstName, lastName, email, phone
    }

    var body: some View {
        ZStack {
            AppBackdrop().ignoresSafeArea()

            VStack(spacing: 0) {
                setupProgressBar

                Group {
                    switch step {
                    case .name:
                        nameStep
                    case .contact:
                        contactStep
                    case .firstTransaction:
                        firstTransactionStep
                    case .cardSetup:
                        cardSetupStep
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.spring(duration: 0.45), value: step)
            }
        }
    }

    // MARK: Steps

    private var nameStep: some View {
        SetupStepWrapper(
            icon: "person.fill",
            iconColors: [Color(hex: "4F8EF7") ?? .blue, Color(hex: "2D5BA3") ?? .blue],
            title: "What's your name?",
            subtitle: "Personalise your experience — your greeting and profile will use this.",
            stepTag: "name"
        ) {
            VStack(spacing: 14) {
                SetupTextField("First Name", text: $firstName, icon: "person")
                    .focused($focus, equals: .firstName)
                SetupTextField("Last Name (optional)", text: $lastName, icon: "person.badge.plus")
                    .focused($focus, equals: .lastName)

                if showValidation && firstName.trimmingCharacters(in: .whitespaces).isEmpty {
                    validationMessage("Please enter your first name.")
                }
            }
        } onNext: {
            if firstName.trimmingCharacters(in: .whitespaces).isEmpty {
                showValidation = true
            } else {
                showValidation = false
                store.saveUserName(first: firstName.trimmingCharacters(in: .whitespaces),
                                   last: lastName.trimmingCharacters(in: .whitespaces))
                withAnimation(.spring(duration: 0.45)) { step = .contact }
            }
        }
    }

    private var contactStep: some View {
        SetupStepWrapper(
            icon: "envelope.fill",
            iconColors: [Color(hex: "6E44C8") ?? .purple, Color(hex: "9B59B6") ?? .purple],
            title: "Contact info",
            subtitle: "Completely optional — used only to personalise your profile within the app.",
            stepTag: "contact"
        ) {
            VStack(spacing: 14) {
                SetupTextField("Email (optional)", text: $email, icon: "envelope", keyboard: .emailAddress)
                    .focused($focus, equals: .email)
                SetupTextField("Phone (optional)", text: $phone, icon: "phone", keyboard: .phonePad)
                    .focused($focus, equals: .phone)
            }
        } onNext: {
            store.saveContactInfo(email: email.trimmingCharacters(in: .whitespaces),
                                  phone: phone.trimmingCharacters(in: .whitespaces))
            withAnimation(.spring(duration: 0.45)) { step = .firstTransaction }
        }
    }

    private var firstTransactionStep: some View {
        SetupStepWrapper(
            icon: "plus.circle.fill",
            iconColors: [Color(hex: "2EC4B6") ?? .teal, Color(hex: "1A8F85") ?? .teal],
            title: "Add your first transaction",
            subtitle: "Log one income or expense now to see your dashboard come alive.",
            stepTag: "firstTransaction",
            nextLabel: "Skip for now"
        ) {
            FirstRunInlineCard(onAddTransaction: {})
        } onNext: {
            withAnimation(.spring(duration: 0.45)) { step = .cardSetup }
        }
        .sheet(isPresented: $store.showingFirstTransactionSheet) {
            AddTransactionView(onSaveComplete: {
                withAnimation(.spring(duration: 0.45)) { step = .cardSetup }
            })
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .environmentObject(store)
        }
    }

    private var cardSetupStep: some View {
        CardSetupStepView {
            store.completeOnboarding()
            onFinish()
        }
    }

    private var setupProgressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(stepIndex >= i ? Color.accentColor : Color.secondary.opacity(0.25))
                    .frame(height: 4)
                    .animation(.spring(duration: 0.4), value: step)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private var stepIndex: Int {
        switch step {
        case .name: return 0
        case .contact: return 1
        case .firstTransaction: return 2
        case .cardSetup: return 3
        }
    }

    @ViewBuilder
    private func validationMessage(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
            Text(text)
                .font(.caption)
                .foregroundStyle(.red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}

// MARK: - Setup Step Wrapper

struct SetupStepWrapper<Fields: View>: View {
    let icon: String
    let iconColors: [Color]
    let title: String
    let subtitle: String
    let stepTag: String
    var nextLabel: String = "Continue"
    @ViewBuilder var fields: Fields
    let onNext: () -> Void

    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(colors: iconColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 76, height: 76)
                        .shadow(color: iconColors.first?.opacity(0.4) ?? .clear, radius: 20, y: 10)
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(appeared ? 1 : 0.7)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.6, bounce: 0.3).delay(0.05), value: appeared)

                // Title + subtitle
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(.title, weight: .bold))
                        .offset(y: appeared ? 0 : 16)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(duration: 0.5).delay(0.1), value: appeared)

                    Text(subtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .offset(y: appeared ? 0 : 16)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(duration: 0.5).delay(0.15), value: appeared)
                }

                // Fields
                fields
                    .offset(y: appeared ? 0 : 16)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.5).delay(0.2), value: appeared)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: nextLabel, action: onNext)
                .padding(.horizontal, 28)
                .padding(.bottom, 36)
                .background(.ultraThinMaterial)
        }
        .onAppear { appeared = true }
        .onDisappear { appeared = false }
    }
}

// MARK: - Setup Text Field

struct SetupTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboard: UIKeyboardType = .default

    init(_ placeholder: String, text: Binding<String>, icon: String, keyboard: UIKeyboardType = .default) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.keyboard = keyboard
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - First Run Inline Card

struct FirstRunInlineCard: View {
    @EnvironmentObject private var store: FinanceStore
    let onAddTransaction: () -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Your dashboard waits for real data.")
                    .font(.headline)

                Text("Tap below to log your first income or expense. You can also skip and add it from the home screen later.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    store.showingFirstTransactionSheet = true
                } label: {
                    Label("Add first transaction", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Card Setup Step

struct CardSetupStepView: View {
    @EnvironmentObject private var store: FinanceStore
    let onFinish: () -> Void

    @State private var appeared = false
    @State private var cardGenerated = false
    @State private var isFlipped = false
    @State private var cardScale: CGFloat = 0.8

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "1A1A2E") ?? .black, Color(hex: "0F3460") ?? .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                            .shadow(color: (Color(hex: "4F8EF7") ?? .blue).opacity(0.45), radius: 18, y: 8)
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(appeared ? 1 : 0.7)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.6, bounce: 0.3).delay(0.05), value: appeared)

                    Text("Your ExpenseTracker Card")
                        .font(.system(.title, weight: .bold))
                        .offset(y: appeared ? 0 : 16)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(duration: 0.5).delay(0.1), value: appeared)

                    Text("A virtual card that lives inside the app — representing your financial identity here, not in any bank.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .offset(y: appeared ? 0 : 16)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(duration: 0.5).delay(0.15), value: appeared)
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)

                Spacer().frame(height: 28)

                ZStack {
                    miniCardFront
                        .opacity(isFlipped ? 0 : 1)
                        .rotation3DEffect(
                            .degrees(isFlipped ? 180 : 0),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.4
                        )

                    miniCardBack
                        .opacity(isFlipped ? 1 : 0)
                        .rotation3DEffect(
                            .degrees(isFlipped ? 0 : -180),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.4
                        )
                }
                .frame(height: 190)
                .padding(.horizontal, 28)
                .scaleEffect(cardScale)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.6, bounce: 0.25).delay(0.2), value: appeared)
                .onTapGesture {
                    guard cardGenerated || store.cardGenerated else { return }
                    withAnimation(.spring(duration: 0.6, bounce: 0.2)) { isFlipped.toggle() }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

                // Tap hint
                if cardGenerated || store.cardGenerated {
                    HStack(spacing: 5) {
                        Image(systemName: "hand.tap.fill").font(.caption2)
                        Text("Tap to flip")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .transition(.opacity)
                }

                Spacer().frame(height: 24)

                VStack(alignment: .leading, spacing: 0) {
                    featureBullet(
                        icon: "person.text.rectangle.fill",
                        iconColor: Color(hex: "4F8EF7") ?? .blue,
                        title: "Your financial identity",
                        body: "Your name, card number, and expiry date are generated uniquely for your account."
                    )
                    divider
                    featureBullet(
                        icon: "chart.bar.fill",
                        iconColor: Color(hex: "2EC4B6") ?? .teal,
                        title: "Live balance on the back",
                        body: "Flip the card anytime to see your current month's available balance, income, and expenses."
                    )
                    divider
                    featureBullet(
                        icon: "lock.shield.fill",
                        iconColor: Color(hex: "6E44C8") ?? .purple,
                        title: "Private & local",
                        body: "Everything stays on your device. No network calls, no third parties."
                    )
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 28)
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.5).delay(0.3), value: appeared)

                Spacer().frame(height: 18)

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.body)
                        .foregroundStyle(Color(hex: "F4A261") ?? .orange)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Not a real bank card")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color(hex: "F4A261") ?? .orange)
                        Text("This is a virtual display card created by Expense Daily for use within the app only. It has no connection to any bank, payment network, or financial institution. You cannot make purchases or withdrawals with it.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                }
                .padding(14)
                .background((Color(hex: "F4A261") ?? .orange).opacity(0.08),
                             in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder((Color(hex: "F4A261") ?? .orange).opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 28)
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.5).delay(0.35), value: appeared)

                Spacer().frame(height: 100)
            }
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                if !cardGenerated && !store.cardGenerated {
                    Button {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        store.generateCard()
                        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                            cardGenerated = true
                            cardScale = 1.04
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            withAnimation(.spring(duration: 0.4)) { cardScale = 1.0 }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                            withAnimation(.spring(duration: 0.6, bounce: 0.2)) { isFlipped = true }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.body.weight(.semibold))
                            Text("Generate My Card")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "4F8EF7") ?? .blue, Color(hex: "6E44C8") ?? .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                        )
                        .shadow(color: (Color(hex: "4F8EF7") ?? .blue).opacity(0.45), radius: 16, y: 8)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Already generated — just proceed
                    PrimaryButton(title: "Continue to Home") {
                        store.completeOnboarding()
                        onFinish()
                    }
                }

                // Skip link
                if !cardGenerated && !store.cardGenerated {
                    Button("Skip for now") {
                        store.completeOnboarding()
                        onFinish()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 36)
            .padding(.top, 12)
            .background(.ultraThinMaterial)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.55, bounce: 0.2).delay(0.05)) { appeared = true }
            if store.cardGenerated { cardGenerated = true }
        }
    }

    // MARK: - Mini card front

    private var miniCardFront: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "1A1A2E") ?? .black, Color(hex: "16213E") ?? .black, Color(hex: "0F3460") ?? .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(RadialGradient(
                    colors: [Color(hex: "4F8EF7")?.opacity(0.3) ?? .clear, .clear],
                    center: .center, startRadius: 0, endRadius: 140
                ))
                .frame(width: 280).offset(x: 70, y: -40)
            Circle()
                .fill(RadialGradient(
                    colors: [Color(hex: "6E44C8")?.opacity(0.22) ?? .clear, .clear],
                    center: .center, startRadius: 0, endRadius: 110
                ))
                .frame(width: 220).offset(x: -90, y: 70)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    HStack(spacing: 6) {
                        Image("AppLogo")
                            .resizable().scaledToFit()
                            .frame(width: 26, height: 26)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        Text("Expense\nTracker")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer()
                    Text("ACTIVE")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(.green.opacity(0.7))
                        .kerning(1.5)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(.green.opacity(0.15), in: Capsule())
                }
                Spacer()
                // Chip
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(hex: "D4AF37") ?? .yellow, Color(hex: "AA8C2C") ?? .yellow],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 34, height: 26)
                    .padding(.bottom, 7)
                // Number
                Text(cardGenerated || store.cardGenerated
                     ? maskedNumber
                     : "•••• •••• •••• ••••")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(cardGenerated || store.cardGenerated ? 1 : 0.4))
                    .padding(.bottom, 10)
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CARDHOLDER")
                            .font(.system(size: 6.5, weight: .medium)).foregroundStyle(.white.opacity(0.6)).kerning(0.8)
                        Text(cardGenerated || store.cardGenerated
                             ? store.userDisplayName.uppercased()
                             : "YOUR NAME")
                            .font(.system(size: 11, weight: .bold)).foregroundStyle(.white).lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("VALID THRU")
                            .font(.system(size: 6.5, weight: .medium)).foregroundStyle(.white.opacity(0.6)).kerning(0.8)
                        Text(cardGenerated || store.cardGenerated ? store.cardExpiry : "MM/YY")
                            .font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(.white)
                    }
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 16)).foregroundStyle(.white.opacity(0.6)).padding(.leading, 6)
                }
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 20, y: 10)
    }

    // MARK: - Mini card back

    private var miniCardBack: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0F3460") ?? .blue, Color(hex: "16213E") ?? .black, Color(hex: "1A1A2E") ?? .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // Stripe
            VStack(spacing: 0) {
                Rectangle().fill(.black.opacity(0.85)).frame(height: 36).padding(.top, 22)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 65)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AVAILABLE BALANCE")
                            .font(.system(size: 6.5, weight: .semibold)).foregroundStyle(.white.opacity(0.55)).kerning(1.2)
                        Text(cardGenerated || store.cardGenerated ? "Tap to see" : "Generate card first")
                            .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    }
                    Spacer()
                    Circle()
                        .fill(Color(hex: "2EC4B6") ?? .teal)
                        .frame(width: 8, height: 8)
                        .shadow(color: (Color(hex: "2EC4B6") ?? .teal).opacity(0.7), radius: 5)
                }
                Spacer()
                HStack {
                    Text("•••• •••• •••• \(store.cardLast4)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    Image(systemName: "wave.3.right").font(.system(size: 13)).foregroundStyle(.white.opacity(0.45))
                }
            }
            .padding(.horizontal, 18).padding(.bottom, 16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 20, y: 10)
        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
    }

    private var maskedNumber: String {
        let parts = store.cardNumber.components(separatedBy: " ")
        guard parts.count == 4 else { return "•••• •••• •••• ••••" }
        return "\(parts[0]) \(parts[1]) •••• \(parts[3])"
    }

    // MARK: - Helpers

    private var divider: some View {
        Divider().padding(.leading, 58).opacity(0.4)
    }

    private func featureBullet(icon: String, iconColor: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Shared Primary Button


struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.accentColor.opacity(0.4), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
    }
}
