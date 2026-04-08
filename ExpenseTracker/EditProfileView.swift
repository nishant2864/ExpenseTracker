import PhotosUI
import SwiftUI

// MARK: - Edit Profile View

struct EditProfileView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    // Editable copies of profile fields
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""

    // Avatar state
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var pendingImageData: Data? = nil           // new image chosen but not yet saved
    @State private var showAvatarSourcePicker = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false

    // Convenience: what image should the preview show?
    private var previewImageData: Data? { pendingImageData ?? store.profileImageData }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop().ignoresSafeArea()

                ScrollView {

                    VStack(spacing: 28) {

                        // MARK: Avatar picker
                        avatarPicker

                        // MARK: Personal info form
                        personalInfoForm

                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 60)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveAndDismiss() }
                        .fontWeight(.semibold)
                }
            }
            // Avatar source action sheet
            .confirmationDialog("Update Profile Picture", isPresented: $showAvatarSourcePicker, titleVisibility: .visible) {
                Button("Take Photo") { showCamera = true }
                Button("Choose from Library") { showPhotoPicker = true }
                if store.profileImageData != nil || pendingImageData != nil {
                    Button("Remove Photo", role: .destructive) {
                        pendingImageData = nil
                        store.profileImageData = nil
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            // Photos library picker
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        pendingImageData = data
                    }
                }
            }
            // Camera sheet
            .sheet(isPresented: $showCamera) {
                CameraPickerView { image in
                    if let data = image.jpegData(compressionQuality: 0.85) {
                        pendingImageData = data
                    }
                }
            }
        }
        .onAppear(perform: populateFields)
    }

    // MARK: - Avatar Picker UI

    private var avatarPicker: some View {
        VStack(spacing: 14) {
            Button {
                showAvatarSourcePicker = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    // Avatar image or initials
                    ZStack {
                        if let data = previewImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
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
                                .frame(width: 100, height: 100)

                            Text(firstName.prefix(1).uppercased().isEmpty
                                 ? "?"
                                 : String(firstName.prefix(1).uppercased()))
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .shadow(color: .black.opacity(0.18), radius: 16, y: 6)

                    // Camera badge
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 30, height: 30)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 4, y: 4)
                }
            }
            .buttonStyle(.plain)

            Text("Change picture")
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Personal Info Form

    private var personalInfoForm: some View {
        VStack(spacing: 0) {
            formField(icon: "person.fill",   label: "First Name", placeholder: "First name",    text: $firstName)
            Divider().padding(.leading, 52)
            formField(icon: "person.2.fill", label: "Last Name",  placeholder: "Last name",     text: $lastName)
            Divider().padding(.leading, 52)
            formField(icon: "envelope.fill", label: "Email",      placeholder: "Email address", text: $email, keyboardType: .emailAddress)
            Divider().padding(.leading, 52)
            formField(icon: "phone.fill",    label: "Phone",      placeholder: "Phone number",  text: $phone, keyboardType: .phonePad, isLast: true)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .modifier(EditFormCardModifier())
    }

    @ViewBuilder
    private func formField(
        icon: String,
        label: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        isLast: Bool = false
    ) -> some View {
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
                TextField(placeholder, text: text)
                    .font(.subheadline.weight(.medium))
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Helpers

    private func populateFields() {
        firstName = store.userFirstName
        lastName  = store.userLastName
        email     = store.userEmail
        phone     = store.userPhone
    }

    private func saveAndDismiss() {
        store.saveUserName(first: firstName.trimmingCharacters(in: .whitespaces),
                           last: lastName.trimmingCharacters(in: .whitespaces))
        store.saveContactInfo(email: email.trimmingCharacters(in: .whitespaces),
                              phone: phone.trimmingCharacters(in: .whitespaces))
        if let data = pendingImageData {
            store.saveProfileImage(data)
        }
        dismiss()
    }
}

// MARK: - Glass card modifier for the edit form

private struct EditFormCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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

// MARK: - Camera Picker (UIImagePickerController wrapper)

struct CameraPickerView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) { self.onCapture = onCapture }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            picker.dismiss(animated: true)
            if let image { onCapture(image) }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

