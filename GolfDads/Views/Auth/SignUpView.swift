//
//  SignUpView.swift
//  GolfDads
//
//  Sign up screen for new user registration
//

import SwiftUI

struct SignUpView: View {

    let authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var notificationManager: NotificationManager

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "flag.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.3))
                                .padding(.top, 40)

                            Text("Join Three Putt")
                                .font(.title.bold())

                            Text("Create your account")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 20)

                        // Form
                        VStack(spacing: 16) {
                            // Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.secondary)

                                TextField("", text: $name, prompt: Text("John Doe").foregroundColor(.secondary))
                                    .textContentType(.name)
                                    .autocapitalization(.words)
                                    .padding()
                                    .background(Color(uiColor: .systemBackground))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }

                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.secondary)

                                ZStack(alignment: .leading) {
                                    if email.isEmpty {
                                        Text("your@email.com")
                                            .foregroundColor(.secondary.opacity(0.5))
                                            .padding(.leading, 16)
                                    }
                                    TextField("", text: $email)
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .textInputAutocapitalization(.never)
                                        .padding()
                                }
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }

                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.secondary)

                                HStack {
                                    if showPassword {
                                        TextField("At least 8 characters", text: $password)
                                            .textContentType(.newPassword)
                                    } else {
                                        SecureField("At least 8 characters", text: $password)
                                            .textContentType(.newPassword)
                                    }

                                    Button(action: { showPassword.toggle() }) {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(passwordFieldBorderColor, lineWidth: 1)
                                )

                                if !password.isEmpty && password.count < 8 {
                                    Text("Password must be at least 8 characters")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }

                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.secondary)

                                HStack {
                                    if showConfirmPassword {
                                        TextField("Re-enter password", text: $confirmPassword)
                                            .textContentType(.newPassword)
                                    } else {
                                        SecureField("Re-enter password", text: $confirmPassword)
                                            .textContentType(.newPassword)
                                    }

                                    Button(action: { showConfirmPassword.toggle() }) {
                                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(confirmPasswordFieldBorderColor, lineWidth: 1)
                                )

                                if !confirmPassword.isEmpty && password != confirmPassword {
                                    Text("Passwords do not match")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // Error Message
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(.callout)
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                                .multilineTextAlignment(.center)
                        }

                        // Sign Up Button
                        Button(action: handleSignUp) {
                            ZStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Sign Up")
                                        .font(.headline)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                Color(red: 0.2, green: 0.6, blue: 0.3)
                                    .opacity(isFormValid ? 1.0 : 0.5)
                            )
                            .cornerRadius(12)
                        }
                        .disabled(!isFormValid || authManager.isLoading)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                        // Terms of Service
                        Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                dismiss()

                // Request notification permission after successful signup
                Task {
                    await requestNotificationPermissionIfNeeded()
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 8 &&
        password == confirmPassword
    }

    private var passwordFieldBorderColor: Color {
        if password.isEmpty {
            return Color.gray.opacity(0.2)
        }
        return password.count >= 8 ? Color.green.opacity(0.5) : Color.red.opacity(0.5)
    }

    private var confirmPasswordFieldBorderColor: Color {
        if confirmPassword.isEmpty {
            return Color.gray.opacity(0.2)
        }
        return password == confirmPassword ? Color.green.opacity(0.5) : Color.red.opacity(0.5)
    }

    // MARK: - Actions

    private func handleSignUp() {
        authManager.clearError()

        Task {
            await authManager.signUp(email: email, password: password, name: name)
        }
    }

    private func requestNotificationPermissionIfNeeded() async {
        // Only request if permission hasn't been determined yet
        if notificationManager.authorizationStatus == .notDetermined {
            await notificationManager.requestAuthorization()
        }
    }
}

#Preview {
    SignUpView(authManager: AuthenticationManager())
}
