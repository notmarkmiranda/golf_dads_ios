//
//  EditProfileView.swift
//  GolfDads
//
//  View for editing user profile information
//

import SwiftUI

struct EditProfileView: View {
    let authManager: AuthenticationManager
    let user: AuthenticatedUser

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var venmoHandle: String
    @State private var handicapText: String
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(authManager: AuthenticationManager, user: AuthenticatedUser) {
        self.authManager = authManager
        self.user = user
        _name = State(initialValue: user.name)
        _venmoHandle = State(initialValue: user.venmoHandle ?? "")
        _handicapText = State(initialValue: user.handicap != nil ? String(format: "%.1f", user.handicap!) : "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .autocapitalization(.words)
                }

                Section {
                    TextField("Venmo Handle", text: $venmoHandle)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .onChange(of: venmoHandle) { oldValue, newValue in
                            // Auto-add @ if user starts typing without it
                            if !newValue.isEmpty && !newValue.hasPrefix("@") {
                                venmoHandle = "@" + newValue
                            }
                        }
                } header: {
                    Text("Venmo Handle")
                } footer: {
                    Text("Your Venmo username for collecting payments (automatically adds @ if missing)")
                }

                Section {
                    TextField("Handicap", text: $handicapText)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Golf Handicap")
                } footer: {
                    Text("Your golf handicap index (0-54.0). Leave blank if you don't have one.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveProfile()
                        }
                    }
                    .disabled(isLoading || name.isEmpty)
                }
            }
            .disabled(isLoading)
        }
    }

    private func saveProfile() async {
        isLoading = true
        errorMessage = nil

        // Validate and convert handicap
        var handicap: Double? = nil
        if !handicapText.isEmpty {
            if let value = Double(handicapText) {
                if value < 0 || value > 54.0 {
                    errorMessage = "Handicap must be between 0 and 54.0"
                    isLoading = false
                    return
                }
                handicap = value
            } else {
                errorMessage = "Handicap must be a valid number"
                isLoading = false
                return
            }
        }

        // Prepare venmo handle (remove if empty)
        let finalVenmoHandle = venmoHandle.trimmingCharacters(in: .whitespaces).isEmpty ? nil : venmoHandle

        do {
            try await updateProfile(
                name: name,
                venmoHandle: finalVenmoHandle,
                handicap: handicap
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func updateProfile(name: String, venmoHandle: String?, handicap: Double?) async throws {
        guard let token = authManager.token else {
            throw APIError.unauthorized(message: "Not authenticated")
        }

        struct UpdateProfileRequest: Encodable {
            let user: UserUpdate

            struct UserUpdate: Encodable {
                let name: String
                let venmoHandle: String?
                let handicap: Double?
            }
        }

        let request = UpdateProfileRequest(
            user: UpdateProfileRequest.UserUpdate(
                name: name,
                venmoHandle: venmoHandle,
                handicap: handicap
            )
        )

        let networkService = NetworkService()
        let updatedUser: AuthenticatedUser = try await networkService.patch(
            endpoint: .updateProfile,
            body: request,
            requiresAuth: true
        )

        // Update the auth manager with new user data
        await authManager.updateCurrentUser(updatedUser)
    }
}

#Preview {
    EditProfileView(
        authManager: AuthenticationManager(),
        user: AuthenticatedUser(
            id: 1,
            email: "test@example.com",
            name: "Test User",
            avatarUrl: nil,
            provider: nil,
            venmoHandle: "@testuser",
            handicap: 15.5
        )
    )
}
