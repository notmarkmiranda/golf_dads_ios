//
//  CreateTeeTimeView.swift
//  GolfDads
//
//  Create new tee time posting
//

import SwiftUI

struct CreateTeeTimeView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var courseName: String = ""
    @State private var teeTime: Date = Date().addingTimeInterval(86400) // Default to tomorrow
    @State private var availableSpots: Int = 1
    @State private var totalSpots: Int = 4
    @State private var notes: String = ""
    @State private var isPublic: Bool = true
    @State private var includeTotalSpots: Bool = true

    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false

    private let teeTimeService: TeeTimeServiceProtocol

    init(teeTimeService: TeeTimeServiceProtocol = TeeTimeService()) {
        self.teeTimeService = teeTimeService
    }

    var body: some View {
        NavigationView {
            Form {
                // Course Information
                Section("Course Information") {
                    TextField("Course Name", text: $courseName)
                        .autocapitalization(.words)

                    DatePicker(
                        "Tee Time",
                        selection: $teeTime,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                // Availability
                Section("Availability") {
                    Picker("Available Spots", selection: $availableSpots) {
                        ForEach(1...4, id: \.self) { count in
                            Text("\(count) \(count == 1 ? "spot" : "spots")")
                                .tag(count)
                        }
                    }

                    Toggle("Include Total Spots", isOn: $includeTotalSpots)

                    if includeTotalSpots {
                        Picker("Total Spots", selection: $totalSpots) {
                            ForEach(availableSpots...4, id: \.self) { count in
                                Text("\(count) \(count == 1 ? "spot" : "spots")")
                                    .tag(count)
                            }
                        }
                    }
                }

                // Visibility
                Section("Visibility") {
                    Picker("Who can see this?", selection: $isPublic) {
                        Label("Public", systemImage: "globe")
                            .tag(true)
                        Label("Private Group", systemImage: "lock.fill")
                            .tag(false)
                    }
                    .pickerStyle(.segmented)

                    if isPublic {
                        Text("Anyone can see and reserve this tee time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Only group members can see this (group selection coming soon)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Notes
                Section("Notes") {
                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Error Message
                if let error = errorMessage {
                    Section {
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
            .navigationTitle("Create Tee Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isCreating)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await createTeeTime()
                        }
                    } label: {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text("Create")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isFormValid || isCreating)
                }
            }
            .alert("Tee Time Created!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your tee time at \(courseName) has been posted.")
            }
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        !courseName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Private Methods

    private func createTeeTime() async {
        isCreating = true
        errorMessage = nil

        do {
            let _ = try await teeTimeService.createTeeTimePosting(
                courseName: courseName.trimmingCharacters(in: .whitespaces),
                teeTime: teeTime,
                availableSpots: availableSpots,
                totalSpots: includeTotalSpots ? totalSpots : nil,
                notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
                groupId: nil // TODO: Add group selection
            )
            showSuccessAlert = true
        } catch {
            errorMessage = "Failed to create tee time: \(error.localizedDescription)"
        }

        isCreating = false
    }
}

#Preview {
    CreateTeeTimeView()
}
