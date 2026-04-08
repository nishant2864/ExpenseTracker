import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showingEditProfile = false
    @State private var showDestroyConfirmation = false
    @State private var showingCardInfo = false

    var body: some View {
        ScrollView {

            VStack(spacing: 28) {
                avatarSection
                personalInfoCard
                cardSection
                settingsCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .background(AppBackdrop().ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditProfile = true
                }
                .fontWeight(.medium)
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(store)
        }
        .confirmationDialog(
            "Destroy Card",
            isPresented: $showDestroyConfirmation,
            titleVisibility: .visible
        ) {
            Button("Destroy Card", role: .destructive) {
                withAnimation(.spring(duration: 0.4)) {
                    store.destroyCard()
                }
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your ExpenseTracker card. You can generate a new one anytime.")
        }
        .alert("About ExpenseTracker Card", isPresented: $showingCardInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("This is a virtual tracking card used within the app only. It has no connection to any bank, payment network, or financial institution. It is not a real credit or debit card.")
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack {
                if let data = store.profileImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 96, height: 96)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.31, green: 0.69, blue: 0.82),
                                         Color(red: 0.50, green: 0.67, blue: 1.00)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)
                    Text(store.userFirstName.prefix(1).uppercased().isEmpty
                         ? "?"
                         : String(store.userFirstName.prefix(1).uppercased()))
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Personal Info Card

    private var personalInfoCard: some View {
        VStack(spacing: 0) {
            infoRow(
                icon: "person.fill",
                label: "Name",
                value: store.userDisplayName == "Friend" ? "—" : store.userDisplayName
            )
            Divider().padding(.leading, 52)
            infoRow(
                icon: "envelope.fill",
                label: "Email",
                value: store.userEmail.isEmpty ? "—" : store.userEmail
            )
            Divider().padding(.leading, 52)
            infoRow(
                icon: "phone.fill",
                label: "Phone",
                value: store.userPhone.isEmpty ? "—" : store.userPhone,
                isLast: true
            )
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .modifier(GlassInfoCardModifier())
    }

    @ViewBuilder
    private func infoRow(icon: String, label: String, value: String, isLast: Bool = false) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Card Section

    private var cardSection: some View {
        VStack(spacing: 0) {
            if store.cardGenerated {
                // Card info row
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("Card")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Button {
                                showingCardInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        Text("•••• •••• •••• \(store.cardLast4)")
                            .font(.subheadline.weight(.medium))
                            .fontDesign(.monospaced)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.body)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider().padding(.leading, 52)

                // Destroy button
                Button {
                    showDestroyConfirmation = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.red.opacity(0.12))
                                .frame(width: 32, height: 32)
                            Image(systemName: "trash.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.red)
                        }
                        Text("Destroy Card")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)

            } else {
                // Generate button
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                        store.generateCard()
                    }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.accentColor.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.accentColor)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text("Card")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Button {
                                    showingCardInfo = true
                                } label: {
                                    Image(systemName: "info.circle")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            Text("Generate ExpenseTracker Card")
                                .font(.subheadline.weight(.medium))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .modifier(GlassInfoCardModifier())
    }

    // MARK: - Settings Card

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Appearance")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            Picker(
                "Appearance",
                selection: Binding(get: { store.appearance }, set: { store.appearance = $0 })
            ) {
                ForEach(AppAppearance.allCases) { appearance in
                    Text(appearance.title).tag(appearance)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .onChange(of: store.appearance) { _, newValue in
                store.setAppearance(newValue)
            }

            Divider()
                .padding(.vertical, 14)
                .padding(.horizontal, 16)

            HStack(spacing: 0) {
                StatPill(label: "Transactions", value: "\(store.currentMonthTransactions.count)")
                StatPill(label: "Categories",   value: "\(store.categories.count)")
                StatPill(label: "Balance",       value: store.formattedCurrency(store.monthlySnapshot.balance))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .modifier(GlassInfoCardModifier())
    }
}

// MARK: - Glass card modifier

private struct GlassInfoCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        } else {
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.10), radius: 16, y: 6)
        }
    }
}
