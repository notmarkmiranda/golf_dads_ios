//
//  ManualCourseEntryView.swift
//  GolfDads
//
//  Manual entry form for adding golf courses not found in API
//

import SwiftUI

struct ManualCourseEntryView: View {

    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCourse: GolfCourse?
    @Binding var manualCourseName: String

    @State private var courseName: String
    @State private var clubName: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var phone: String = ""
    @State private var website: String = ""

    @State private var isSaving = false
    @State private var errorMessage: String?

    private let golfCourseService: GolfCourseServiceProtocol

    init(
        selectedCourse: Binding<GolfCourse?>,
        manualCourseName: Binding<String>,
        initialCourseName: String = "",
        golfCourseService: GolfCourseServiceProtocol = GolfCourseService()
    ) {
        self._selectedCourse = selectedCourse
        self._manualCourseName = manualCourseName
        self._courseName = State(initialValue: initialCourseName)
        self.golfCourseService = golfCourseService
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Course Information") {
                    TextField("Course Name", text: $courseName)
                        .textInputAutocapitalization(.words)

                    TextField("Club Name (optional)", text: $clubName)
                        .textInputAutocapitalization(.words)
                }

                Section("Location") {
                    TextField("Address (optional)", text: $address)
                        .textInputAutocapitalization(.words)

                    TextField("City (optional)", text: $city)
                        .textInputAutocapitalization(.words)

                    TextField("State (optional)", text: $state)
                        .textInputAutocapitalization(.characters)

                    TextField("Zip Code (optional)", text: $zipCode)
                        .keyboardType(.numberPad)
                }

                Section("Contact Information") {
                    TextField("Phone (optional)", text: $phone)
                        .keyboardType(.phonePad)

                    TextField("Website (optional)", text: $website)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                }

                Section {
                    Text("This course will be saved to the database and available for future searches.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

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
            .navigationTitle("Add Golf Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await saveCourse()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isFormValid || isSaving)
                }
            }
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        !courseName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Private Methods

    private func saveCourse() async {
        isSaving = true
        errorMessage = nil

        let trimmedName = courseName.trimmingCharacters(in: .whitespaces)
        let trimmedClubName = clubName.trimmingCharacters(in: .whitespaces)
        let trimmedAddress = address.trimmingCharacters(in: .whitespaces)
        let trimmedCity = city.trimmingCharacters(in: .whitespaces)
        let trimmedState = state.trimmingCharacters(in: .whitespaces)
        let trimmedZipCode = zipCode.trimmingCharacters(in: .whitespaces)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
        let trimmedWebsite = website.trimmingCharacters(in: .whitespaces)

        // Create a GolfCourse object for caching
        let courseToCache = GolfCourse(
            id: nil,
            externalId: nil,
            name: trimmedName,
            clubName: trimmedClubName.isEmpty ? nil : trimmedClubName,
            address: trimmedAddress.isEmpty ? nil : trimmedAddress,
            city: trimmedCity.isEmpty ? nil : trimmedCity,
            state: trimmedState.isEmpty ? nil : trimmedState,
            zipCode: trimmedZipCode.isEmpty ? nil : trimmedZipCode,
            country: nil,
            latitude: nil,
            longitude: nil,
            phone: trimmedPhone.isEmpty ? nil : trimmedPhone,
            website: trimmedWebsite.isEmpty ? nil : trimmedWebsite,
            distanceMiles: nil,
            isFavorite: nil
        )

        do {
            // Cache the course to the backend
            let cachedCourse = try await golfCourseService.cacheCourse(courseToCache)
            selectedCourse = cachedCourse
            manualCourseName = "" // Clear manual name since we have a full course
            dismiss()
        } catch {
            errorMessage = "Failed to save course: \(error.localizedDescription)"
        }

        isSaving = false
    }
}

#Preview {
    ManualCourseEntryView(
        selectedCourse: .constant(nil),
        manualCourseName: .constant(""),
        initialCourseName: "Test Course"
    )
}
