//
//  TeeTimeDetailView.swift
//  GolfDads
//
//  Detailed view of a tee time posting with reservation functionality
//

import SwiftUI

struct TeeTimeDetailView: View {

    let initialPosting: TeeTimePosting

    @State private var posting: TeeTimePosting
    @State private var spotsToReserve: Int = 1
    @State private var isReserving = false
    @State private var isLoadingPosting = false
    @State private var reservationError: String?
    @State private var showSuccessAlert = false
    @State private var successMessage: String = ""
    @State private var myExistingReservation: Reservation?

    @Environment(\.dismiss) private var dismiss

    private let reservationService: ReservationServiceProtocol
    private let teeTimeService: TeeTimeServiceProtocol
    @State private var currentUserId: Int?

    // Calendar integration
    @StateObject private var calendarSyncManager = CalendarSyncManager()
    @State private var showCalendarPrompt = false
    @State private var pendingReservation: Reservation?

    init(
        posting: TeeTimePosting,
        reservationService: ReservationServiceProtocol = ReservationService(),
        teeTimeService: TeeTimeServiceProtocol = TeeTimeService()
    ) {
        self.initialPosting = posting
        self._posting = State(initialValue: posting)
        self.reservationService = reservationService
        self.teeTimeService = teeTimeService
    }

    // Check if current user has an existing reservation
    private var hasExistingReservation: Bool {
        myExistingReservation != nil
    }

    // Available spots including the user's current reservation
    private var availableSpotsForUpdate: Int {
        if let existing = myExistingReservation {
            return posting.availableSpots + existing.spotsReserved
        }
        return posting.availableSpots
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(posting.courseName)
                        .font(.title)
                        .fontWeight(.bold)

                    HStack {
                        if posting.isPublic {
                            Label("Public", systemImage: "globe")
                                .foregroundColor(.blue)
                        } else {
                            Label("Private Group", systemImage: "lock.fill")
                                .foregroundColor(.orange)
                        }

                        if posting.isPast {
                            Label("Past", systemImage: "clock.badge.xmark")
                                .foregroundColor(.red)
                        }
                    }
                    .font(.subheadline)
                }

                Divider()

                // Date & Time Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Date & Time", systemImage: "calendar")
                        .font(.headline)

                    HStack {
                        VStack(alignment: .leading) {
                            Text(posting.teeTime, style: .date)
                                .font(.title3)
                            Text(posting.teeTime, style: .time)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Divider()

                // Availability Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Availability", systemImage: "person.2")
                        .font(.headline)

                    HStack(spacing: 4) {
                        Text("\(posting.availableSpots)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(posting.availableSpots > 0 ? .green : .red)

                        Text("spots available")
                            .foregroundColor(.secondary)

                        if let totalSpots = posting.totalSpots {
                            Text("of \(totalSpots)")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Notes Section (if present)
                if let notes = posting.notes, !notes.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Notes", systemImage: "note.text")
                            .font(.headline)

                        Text(notes)
                            .foregroundColor(.secondary)
                    }
                }

                // Reservations Section (visible to all users)
                if let reservations = posting.reservations, !reservations.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Reservations (\(reservations.count))", systemImage: "person.2.fill")
                            .font(.headline)

                        ForEach(reservations) { reservation in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Text(reservation.userEmail)
                                            .font(.body)

                                        // Show "You" badge if this is the current user's reservation
                                        if reservation.userId == currentUserId {
                                            Text("(You)")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(4)
                                        }
                                    }

                                    Text("Reserved \(reservation.createdAt, style: .relative) ago")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text("\(reservation.spotsReserved) \(reservation.spotsReserved == 1 ? "spot" : "spots")")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }

                // Reservation Section
                if !posting.isPast && (posting.availableSpots > 0 || hasExistingReservation) {
                    Divider()

                    VStack(alignment: .leading, spacing: 16) {
                        Label(hasExistingReservation ? "Update Reservation" : "Reserve Spots", systemImage: "checkmark.circle")
                            .font(.headline)

                        // Show current reservation if exists
                        if let existing = myExistingReservation {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Your current reservation")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("\(existing.spotsReserved) \(existing.spotsReserved == 1 ? "spot" : "spots")")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }

                        // Spot Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text(hasExistingReservation ? "Change to" : "Number of spots")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Picker("Spots", selection: $spotsToReserve) {
                                ForEach(1...min(availableSpotsForUpdate, 4), id: \.self) { count in
                                    Text("\(count) \(count == 1 ? "spot" : "spots")")
                                        .tag(count)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Reserve/Update Button
                        Button {
                            Task {
                                await saveReservation()
                            }
                        } label: {
                            if isReserving {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text(hasExistingReservation ? "Update to \(spotsToReserve) \(spotsToReserve == 1 ? "Spot" : "Spots")" : "Reserve \(spotsToReserve) \(spotsToReserve == 1 ? "Spot" : "Spots")")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(isReserving || (hasExistingReservation && spotsToReserve == myExistingReservation?.spotsReserved))

                        // Cancel Reservation Button (if user has one)
                        if hasExistingReservation {
                            Button(role: .destructive) {
                                Task {
                                    await cancelReservation()
                                }
                            } label: {
                                if isReserving {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.red)
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Text("Cancel Reservation")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .disabled(isReserving)
                        }

                        // Error Message
                        if let error = reservationError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Past or Unavailable Message
                if posting.isPast {
                    VStack(spacing: 8) {
                        Image(systemName: "clock.badge.xmark")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("This tee time has passed")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else if posting.availableSpots == 0 {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        Text("This tee time is fully booked")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            }
            .padding()
        }
        .navigationTitle("Tee Time Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCurrentUserId()
            await refreshPosting()
            loadExistingReservation()
        }
        .alert("Success!", isPresented: $showSuccessAlert) {
            Button("OK") {
                // Only dismiss if this was a new reservation or update
                // Don't dismiss on cancellation so user can see the updated posting
                if !successMessage.contains("cancelled") {
                    dismiss()
                }
            }
        } message: {
            Text(successMessage)
        }
        .alert("Add to Calendar?", isPresented: $showCalendarPrompt) {
            Button("Add to Calendar") {
                Task {
                    if let reservation = pendingReservation {
                        await calendarSyncManager.syncReservation(reservation, shouldPromptUser: false)
                    }
                    pendingReservation = nil
                }
            }
            Button("Not Now", role: .cancel) {
                pendingReservation = nil
            }
        } message: {
            Text("Would you like to add this tee time to your calendar? It will automatically update if the time changes.")
        }
    }

    // MARK: - Private Methods

    private func loadCurrentUserId() async {
        print("🔍 TeeTimeDetailView: Loading current user ID")
        // Get the current user's ID from keychain
        let keychainService = KeychainService()
        guard let token = keychainService.getToken() else {
            print("   ❌ No token found in keychain")
            return
        }

        // Decode JWT to get user_id (basic JWT decode without verification)
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3,
              let payloadData = Data(base64Encoded: parts[1].base64PaddedString()),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let userId = payload["user_id"] as? Int else {
            print("   ❌ Failed to decode user ID from token")
            return
        }

        currentUserId = userId
        print("   ✅ Current user ID set to: \(userId)")
    }

    private func refreshPosting() async {
        print("🔄 Refreshing posting data...")
        isLoadingPosting = true

        do {
            // Fetch the latest posting data from the API, which includes reservation info
            let freshPosting = try await teeTimeService.getTeeTimePosting(id: posting.id)
            posting = freshPosting
            print("   ✅ Posting refreshed with \(freshPosting.reservations?.count ?? 0) reservations")
        } catch {
            print("   ⚠️ Failed to refresh posting: \(error)")
            // Continue with stale data rather than blocking the user
        }

        isLoadingPosting = false
    }

    private func loadExistingReservation() {
        print("🔍 loadExistingReservation called")
        print("   currentUserId: \(String(describing: currentUserId))")
        print("   posting.reservations: \(String(describing: posting.reservations))")

        // Check if current user has a reservation in the posting's reservations
        guard let currentUserId = currentUserId,
              let reservations = posting.reservations else {
            print("   ❌ Guard failed - currentUserId or reservations is nil")
            return
        }

        print("   ✅ Have currentUserId and reservations")
        print("   Reservations count: \(reservations.count)")

        // Find the reservation for the current user (by userId if available, otherwise skip)
        if let existing = reservations.first(where: { $0.userId == currentUserId }) {
            print("   ✅ Found existing reservation: \(existing)")
            myExistingReservation = Reservation(
                id: existing.id,
                userId: currentUserId,
                teeTimePostingId: posting.id,
                spotsReserved: existing.spotsReserved,
                createdAt: existing.createdAt,
                updatedAt: existing.createdAt,
                teeTimePosting: nil
            )
            spotsToReserve = existing.spotsReserved
            print("   ✅ Set myExistingReservation with \(existing.spotsReserved) spots")
        } else {
            print("   ❌ No reservation found for user \(currentUserId)")
        }
    }

    private func saveReservation() async {
        isReserving = true
        reservationError = nil

        do {
            if let existing = myExistingReservation {
                // Update existing reservation
                let updated = try await reservationService.updateReservation(
                    id: existing.id,
                    spotsReserved: spotsToReserve
                )
                myExistingReservation = updated

                // Auto-update calendar event if exists
                await calendarSyncManager.updateReservationIfNeeded(updated)

                successMessage = "Your reservation has been updated to \(spotsToReserve) \(spotsToReserve == 1 ? "spot" : "spots")."
            } else {
                // Create new reservation
                let created = try await reservationService.createReservation(
                    teeTimePostingId: posting.id,
                    spotsReserved: spotsToReserve
                )
                myExistingReservation = created

                // Show calendar prompt for new reservation
                pendingReservation = created
                showCalendarPrompt = true

                successMessage = "You've successfully reserved \(spotsToReserve) \(spotsToReserve == 1 ? "spot" : "spots") for this tee time."
            }
            showSuccessAlert = true
        } catch {
            reservationError = "Failed to save reservation: \(error.localizedDescription)"
        }

        isReserving = false
    }

    private func cancelReservation() async {
        guard let existing = myExistingReservation else { return }

        isReserving = true
        reservationError = nil

        do {
            try await reservationService.deleteReservation(id: existing.id)

            // Remove from calendar
            await calendarSyncManager.removeReservation(reservationId: existing.id)

            myExistingReservation = nil
            spotsToReserve = 1
            successMessage = "Your reservation has been cancelled."

            // Refresh the posting to show updated available spots
            await refreshPosting()
            loadExistingReservation()

            showSuccessAlert = true
        } catch let error as APIError {
            // If the reservation is already gone (404), treat it as success
            if case .notFound = error {
                myExistingReservation = nil
                spotsToReserve = 1
                successMessage = "Your reservation has been cancelled."

                // Refresh the posting to show updated available spots
                await refreshPosting()
                loadExistingReservation()

                showSuccessAlert = true
            } else {
                reservationError = "Failed to cancel reservation: \(error.localizedDescription)"
            }
        } catch {
            reservationError = "Failed to cancel reservation: \(error.localizedDescription)"
        }

        isReserving = false
    }
}

#Preview {
    NavigationView {
        TeeTimeDetailView(
            posting: TeeTimePosting(
                id: 1,
                userId: 1,
                groupIds: [],
                teeTime: Date().addingTimeInterval(86400),
                courseName: "Pebble Beach Golf Links",
                availableSpots: 2,
                totalSpots: 4,
                notes: "Looking for 2 more players for an early morning round. Bring your A-game!",
                createdAt: Date(),
                updatedAt: Date()
            )
        )
    }
}

// MARK: - Base64 Helper

private extension String {
    /// Adds padding to base64url string to make it valid base64
    func base64PaddedString() -> String {
        var base64 = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainder = base64.count % 4
        if remainder > 0 {
            base64 = base64.padding(toLength: base64.count + 4 - remainder,
                                    withPad: "=",
                                    startingAt: 0)
        }
        return base64
    }
}
