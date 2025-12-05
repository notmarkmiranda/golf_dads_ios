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
            // Home Tab - My Tee Times
            MyTeeTimesView()
                .tabItem {
                    Label("My Tee Times", systemImage: "calendar")
                }

            // Groups Tab
            GroupsView()
                .tabItem {
                    Label("Groups", systemImage: "person.3.fill")
                }

            // Browse Tab
            BrowseView()
                .tabItem {
                    Label("Browse", systemImage: "flag")
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
    @State private var showEditProfile = false

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

                Section("Golf Profile") {
                    HStack {
                        Text("Venmo Handle")
                        Spacer()
                        if let venmoHandle = user.venmoHandle {
                            Text(venmoHandle)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Not set")
                                .foregroundColor(.gray)
                                .italic()
                        }
                    }

                    HStack {
                        Text("Handicap")
                        Spacer()
                        if let handicap = user.handicap {
                            Text(String(format: "%.1f", handicap))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Not set")
                                .foregroundColor(.gray)
                                .italic()
                        }
                    }

                    Button("Edit Profile") {
                        showEditProfile = true
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
        .sheet(isPresented: $showEditProfile) {
            if let user = authManager.currentUser {
                EditProfileView(authManager: authManager, user: user)
            }
        }
    }
}

// Login and SignUp views are in separate files:
// - LoginView.swift
// - SignUpView.swift

#Preview {
    RootView()
}
