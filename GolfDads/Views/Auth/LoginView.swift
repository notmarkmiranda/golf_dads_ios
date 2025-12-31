//
//  LoginView.swift
//  GolfDads
//
//  Login screen with email/password authentication
//

import SwiftUI

struct LoginView: View {

    let authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var notificationManager: NotificationManager

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

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

                            Text("Welcome Back!")
                                .font(.title.bold())

                            Text("Log in to continue")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 20)

                        // Google Sign-In Button
                        Button(action: handleGoogleSignIn) {
                            HStack {
                                Image(systemName: "globe")
                                Text("Continue with Google")
                                    .font(.headline)
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 24)

                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.3))
                            Text("OR")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.3))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)

                        // Form
                        VStack(spacing: 16) {
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
                                        TextField("Enter your password", text: $password)
                                            .textContentType(.password)
                                    } else {
                                        SecureField("Enter your password", text: $password)
                                            .textContentType(.password)
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
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }

                            // Forgot Password (placeholder for now)
                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    // TODO: Implement password reset
                                }
                                .font(.subheadline)
                                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.3))
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

                        // Login Button
                        Button(action: handleLogin) {
                            ZStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Log In")
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

                // Request notification permission after successful login
                Task {
                    await requestNotificationPermissionIfNeeded()
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }

    // MARK: - Actions

    private func handleLogin() {
        authManager.clearError()

        Task {
            await authManager.login(email: email, password: password)
        }
    }

    private func handleGoogleSignIn() {
        authManager.clearError()

        Task {
            do {
                // Create Google Auth Service
                let googleAuthService = GoogleAuthService()

                // Get ID token from Google
                let idToken = try await googleAuthService.signIn()

                // Send to backend via AuthenticationManager
                await authManager.googleSignIn(idToken: idToken)
            } catch {
                // Error handling is done in AuthenticationManager
                print("Google Sign-In error: \(error.localizedDescription)")
            }
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
    LoginView(authManager: AuthenticationManager())
}
