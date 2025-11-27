//
//  RootView.swift
//  GolfDads
//
//  Root view that handles authentication state and navigation
//

import SwiftUI

struct RootView: View {

    @State private var authManager = AuthenticationManager()
    @State private var showLogin = false
    @State private var showSignUp = false

    var body: some View {
        SwiftUI.Group {
            if authManager.isAuthenticated {
                // Main app content (for now, show a placeholder)
                MainTabView(authManager: authManager)
            } else {
                // Authentication flow
                WelcomeView(
                    onLoginTap: { showLogin = true },
                    onSignUpTap: { showSignUp = true }
                )
                .sheet(isPresented: $showLogin) {
                    LoginView(authManager: authManager)
                }
                .sheet(isPresented: $showSignUp) {
                    SignUpView(authManager: authManager)
                }
            }
        }
        .onAppear {
            authManager.checkAuthStatus()
        }
    }
}

// MARK: - Placeholder Main Tab View

struct MainTabView: View {
    let authManager: AuthenticationManager

    var body: some View {
        TabView {
            // Home Tab
            NavigationView {
                VStack(spacing: 20) {
                    Text("Welcome to Golf Dads!")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    if let user = authManager.currentUser {
                        Text("Hello, \(user.name)!")
                            .font(.title2)
                        Text(user.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Logout") {
                        Task {
                            await authManager.logout()
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding()
                .navigationTitle("Home")
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            // Groups Tab
            NavigationView {
                Text("Groups")
                    .navigationTitle("Groups")
            }
            .tabItem {
                Label("Groups", systemImage: "person.3.fill")
            }

            // Tee Times Tab
            NavigationView {
                Text("Tee Times")
                    .navigationTitle("Tee Times")
            }
            .tabItem {
                Label("Tee Times", systemImage: "calendar")
            }

            // Profile Tab
            NavigationView {
                ProfileView(authManager: authManager)
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle.fill")
            }
        }
    }
}

// MARK: - Placeholder Profile View

struct ProfileView: View {
    let authManager: AuthenticationManager

    var body: some View {
        List {
            if let user = authManager.currentUser {
                Section("Profile") {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(user.name)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Email")
                        Spacer()
                        Text(user.email)
                            .foregroundColor(.secondary)
                    }

                    if let provider = user.provider {
                        HStack {
                            Text("Sign-in Method")
                            Spacer()
                            Text(provider.capitalized)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section {
                Button("Logout") {
                    Task {
                        await authManager.logout()
                    }
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Profile")
    }
}

// Login and SignUp views are in separate files:
// - LoginView.swift
// - SignUpView.swift

#Preview {
    RootView()
}
