//
//  NotificationSettingsView.swift
//  GolfDads
//
//  Notification preferences and permission management
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var preferences: NotificationPreferences?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        List {
            // Permission Status Section
            Section {
                permissionStatusRow
            } header: {
                Text("Notification Permission")
            } footer: {
                Text("You must allow notifications in iOS Settings to receive alerts.")
            }

            // Notification Preferences Section
            if notificationManager.authorizationStatus == .authorized {
                Section {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if let prefs = preferences {
                        Toggle("Reservations", isOn: binding(for: \.reservationsEnabled))
                        Toggle("Group Activity", isOn: binding(for: \.groupActivityEnabled))

                        Toggle("Reminders", isOn: binding(for: \.remindersEnabled))

                        if prefs.remindersEnabled {
                            Toggle("24 Hour Reminder", isOn: binding(for: \.reminder24HEnabled))
                                .padding(.leading, 20)
                            Toggle("2 Hour Reminder", isOn: binding(for: \.reminder2HEnabled))
                                .padding(.leading, 20)
                        }
                    }
                } header: {
                    Text("Notification Types")
                } footer: {
                    Text("Choose which notifications you'd like to receive.")
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPreferences()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Permission Status Row

    @ViewBuilder
    private var permissionStatusRow: some View {
        switch notificationManager.authorizationStatus {
        case .notDetermined:
            Button {
                Task {
                    await requestPermission()
                }
            } label: {
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundColor(.blue)
                    Text("Enable Notifications")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }

        case .denied:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bell.slash.fill")
                        .foregroundColor(.red)
                    Text("Notifications Disabled")
                        .foregroundColor(.red)
                }

                Button {
                    openSettings()
                } label: {
                    Text("Open Settings to Enable")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }

        case .authorized:
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.green)
                Text("Notifications Enabled")
                Spacer()
                Text("Active")
                    .foregroundColor(.green)
                    .font(.subheadline)
            }

        case .provisional, .ephemeral:
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.orange)
                Text("Limited Notifications")
                Spacer()
            }

        @unknown default:
            HStack {
                Image(systemName: "bell")
                Text("Unknown Status")
                Spacer()
            }
        }
    }

    // MARK: - Helper Methods

    private func binding(for keyPath: WritableKeyPath<NotificationPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: {
                preferences?[keyPath: keyPath] ?? false
            },
            set: { newValue in
                guard var prefs = preferences else { return }
                prefs[keyPath: keyPath] = newValue
                preferences = prefs

                // Save to backend
                Task {
                    await updatePreferences()
                }
            }
        )
    }

    private func loadPreferences() async {
        isLoading = true
        errorMessage = nil

        do {
            let prefs = try await NetworkService.shared.getNotificationPreferences()
            preferences = prefs
        } catch {
            errorMessage = "Failed to load preferences: \(error.localizedDescription)"
            showError = true
            // Use default preferences if load fails
            preferences = NotificationPreferences.defaultPreferences
        }

        isLoading = false
    }

    private func updatePreferences() async {
        guard let prefs = preferences else { return }

        let update = NotificationPreferencesUpdate(
            reservationsEnabled: prefs.reservationsEnabled,
            groupActivityEnabled: prefs.groupActivityEnabled,
            remindersEnabled: prefs.remindersEnabled,
            reminder24HEnabled: prefs.reminder24HEnabled,
            reminder2HEnabled: prefs.reminder2HEnabled
        )

        do {
            let updated = try await NetworkService.shared.updateNotificationPreferences(update)
            preferences = updated
        } catch {
            errorMessage = "Failed to save preferences: \(error.localizedDescription)"
            showError = true
            // Reload to get correct state from server
            await loadPreferences()
        }
    }

    private func requestPermission() async {
        let granted = await notificationManager.requestAuthorization()

        if granted {
            // Load preferences after permission is granted
            await loadPreferences()
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NavigationView {
        NotificationSettingsView()
            .environmentObject(NotificationManager.shared)
    }
}
