//
//  WelcomeView.swift
//  GolfDads
//
//  Welcome/Onboarding screen - first screen users see
//

import SwiftUI

struct WelcomeView: View {

    var onLoginTap: () -> Void
    var onSignUpTap: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.6, blue: 0.3),  // Golf green
                    Color(red: 0.1, green: 0.4, blue: 0.2)   // Darker green
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Logo/Branding Section
                VStack(spacing: 16) {
                    // Golf flag icon
                    Image(systemName: "flag.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)

                    Text("Three Putt")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Connect. Play. Share.")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // Buttons Section
                VStack(spacing: 16) {
                    // Login Button
                    Button(action: onLoginTap) {
                        Text("Log In")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.3))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }

                    // Sign Up Button
                    Button(action: onSignUpTap) {
                        Text("Sign Up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    WelcomeView(
        onLoginTap: { print("Login tapped") },
        onSignUpTap: { print("Sign up tapped") }
    )
}
