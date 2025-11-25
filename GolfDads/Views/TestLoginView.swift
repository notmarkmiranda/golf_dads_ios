//
//  TestLoginView.swift
//  GolfDads
//
//  Temporary view for testing authentication against local API
//

import SwiftUI

struct TestLoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isLoading = false
    @State private var message = ""
    @State private var isLoggedIn = false
    @State private var currentUser: AuthenticatedUser?

    private let authService = AuthenticationService()

    var body: some View {
        NavigationView {
            Form {
                if !isLoggedIn {
                    // Login/Signup Section
                    Section("Sign Up") {
                        TextField("Name", text: $name)
                            .textContentType(.name)
                            .autocapitalization(.words)

                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)

                        SecureField("Password", text: $password)
                            .textContentType(.password)

                        Button("Sign Up") {
                            Task {
                                await signUp()
                            }
                        }
                        .disabled(name.isEmpty || email.isEmpty || password.isEmpty || isLoading)
                    }

                    Section("Login") {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)

                        SecureField("Password", text: $password)
                            .textContentType(.password)

                        Button("Login") {
                            Task {
                                await login()
                            }
                        }
                        .disabled(email.isEmpty || password.isEmpty || isLoading)
                    }
                } else {
                    // Logged In Section
                    Section("Current User") {
                        if let user = currentUser {
                            Text("ID: \(user.id)")
                            Text("Email: \(user.email)")
                            Text("Name: \(user.name)")
                            if let avatar = user.avatarUrl {
                                Text("Avatar: \(avatar)")
                                    .font(.caption)
                            }
                            Text("Provider: \(user.provider ?? "N/A")")
                        }

                        // Note: "Get Current User" endpoint doesn't exist in API yet
                        // User info is already available from login/signup response

                        Button("Logout") {
                            logout()
                        }
                        .foregroundColor(.red)
                    }
                }

                // Status Section
                Section("Status") {
                    if isLoading {
                        ProgressView("Loading...")
                    }

                    if !message.isEmpty {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(message.contains("Error") || message.contains("Failed") ? .red : .green)
                    }

                    Text("API: \(APIConfiguration.baseURL)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("Logged In: \(authService.isLoggedIn ? "Yes" : "No")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Auth Test")
            .onAppear {
                checkAuthStatus()
            }
        }
    }

    // MARK: - Auth Actions

    private func signUp() async {
        isLoading = true
        message = "Signing up..."

        do {
            let response = try await authService.signUp(email: email, password: password, name: name)
            message = "✅ Signed up successfully!"
            currentUser = response.user
            isLoggedIn = true
            clearFields()
        } catch {
            message = "❌ Sign up failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func login() async {
        isLoading = true
        message = "Logging in..."

        do {
            let response = try await authService.login(email: email, password: password)
            message = "✅ Logged in successfully!"
            currentUser = response.user
            isLoggedIn = true
            clearFields()
        } catch {
            message = "❌ Login failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func getCurrentUser() async {
        isLoading = true
        message = "Fetching user..."

        do {
            let user = try await authService.getCurrentUser()
            message = "✅ User fetched successfully!"
            currentUser = user
        } catch {
            message = "❌ Failed to get user: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func logout() {
        do {
            try authService.logout()
            message = "✅ Logged out successfully!"
            isLoggedIn = false
            currentUser = nil
            clearFields()
        } catch {
            message = "❌ Logout failed: \(error.localizedDescription)"
        }
    }

    private func checkAuthStatus() {
        isLoggedIn = authService.isLoggedIn
        if isLoggedIn {
            message = "Already logged in. Tap 'Get Current User' to fetch details."
        }
    }

    private func clearFields() {
        email = ""
        password = ""
        name = ""
    }
}

#Preview {
    TestLoginView()
}
