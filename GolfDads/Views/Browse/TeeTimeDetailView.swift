//
//  TeeTimeDetailView.swift
//  GolfDads
//
//  Detailed view of a tee time posting with reservation functionality
//

import SwiftUI

struct TeeTimeDetailView: View {

    let posting: TeeTimePosting

    @State private var spotsToReserve: Int = 1
    @State private var isReserving = false
    @State private var reservationError: String?
    @State private var showSuccessAlert = false
    @State private var reservation: Reservation?

    @Environment(\.dismiss) private var dismiss

    private let reservationService: ReservationServiceProtocol

    init(
        posting: TeeTimePosting,
        reservationService: ReservationServiceProtocol = ReservationService()
    ) {
        self.posting = posting
        self.reservationService = reservationService
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

                // Reservation Section
                if !posting.isPast && posting.availableSpots > 0 {
                    Divider()

                    VStack(alignment: .leading, spacing: 16) {
                        Label("Reserve Spots", systemImage: "checkmark.circle")
                            .font(.headline)

                        // Spot Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Number of spots")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Picker("Spots", selection: $spotsToReserve) {
                                ForEach(1...min(posting.availableSpots, 4), id: \.self) { count in
                                    Text("\(count) \(count == 1 ? "spot" : "spots")")
                                        .tag(count)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Reserve Button
                        Button {
                            Task {
                                await makeReservation()
                            }
                        } label: {
                            if isReserving {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Reserve \(spotsToReserve) \(spotsToReserve == 1 ? "Spot" : "Spots")")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(isReserving)

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
        .alert("Reservation Successful!", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("You've successfully reserved \(spotsToReserve) \(spotsToReserve == 1 ? "spot" : "spots") for this tee time.")
        }
    }

    // MARK: - Private Methods

    private func makeReservation() async {
        isReserving = true
        reservationError = nil

        do {
            reservation = try await reservationService.createReservation(
                teeTimePostingId: posting.id,
                spotsReserved: spotsToReserve
            )
            showSuccessAlert = true
        } catch {
            reservationError = "Failed to create reservation: \(error.localizedDescription)"
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
                groupId: nil,
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
