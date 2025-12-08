//
//  CreateTeeTimeView.swift
//  GolfDads
//
//  Create new tee time posting
//

import SwiftUI

struct CreateTeeTimeView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var selectedGolfCourse: GolfCourse?
    @State private var manualCourseName: String = ""
    @State private var showCourseSearch = false
    @State private var teeTime: Date = Date().addingTimeInterval(86400) // Default to tomorrow
    @State private var totalSpots: Int = 4
    @State private var reserveForMyself: Int = 0
    @State private var notes: String = ""
    @State private var isPublic: Bool = true
    @State private var selectedGroupIds: Set<Int> = []
    @State private var availableGroups: [Group] = []
    @State private var isLoadingGroups = false

    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false

    private let teeTimeService: TeeTimeServiceProtocol
    private let groupService: GroupServiceProtocol

    init(
        teeTimeService: TeeTimeServiceProtocol = TeeTimeService(),
        groupService: GroupServiceProtocol = GroupService()
    ) {
        self.teeTimeService = teeTimeService
        self.groupService = groupService
    }

    var body: some View {
        NavigationView {
            Form {
                // Course Information
                Section("Course Information") {
                    // Golf Course Selection Button
                    Button {
                        showCourseSearch = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Golf Course")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                if let course = selectedGolfCourse {
                                    Text(course.name)
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    if !course.displayLocation.isEmpty {
                                        Text(course.displayLocation)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } else if !manualCourseName.isEmpty {
                                    Text(manualCourseName)
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Text("Manual entry (no location)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Tap to select course")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    DatePicker(
                        "Tee Time",
                        selection: $teeTime,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                // Availability
                Section("Availability") {
                    Picker("Total Spots", selection: $totalSpots) {
                        ForEach(1...4, id: \.self) { count in
                            Text("\(count) \(count == 1 ? "spot" : "spots")")
                                .tag(count)
                        }
                    }

                    Picker("Reserve for myself", selection: $reserveForMyself) {
                        Text("None").tag(0)
                        ForEach(1...min(totalSpots, 3), id: \.self) { count in
                            Text("\(count) \(count == 1 ? "spot" : "spots")")
                                .tag(count)
                        }
                    }

                    if reserveForMyself > 0 {
                        Text("\(totalSpots - reserveForMyself) \(totalSpots - reserveForMyself == 1 ? "spot" : "spots") will be available for others")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("All \(totalSpots) \(totalSpots == 1 ? "spot" : "spots") will be available for others")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Visibility
                Section {
                    Picker("Who can see this?", selection: $isPublic) {
                        Label("Public", systemImage: "globe")
                            .tag(true)
                        Label("Private Groups", systemImage: "lock.fill")
                            .tag(false)
                    }
                    .pickerStyle(.segmented)

                    if isPublic {
                        Text("Anyone can see and reserve this tee time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        if isLoadingGroups {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if availableGroups.isEmpty {
                            Text("You don't have any groups yet. Create or join a group first.")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            ForEach(availableGroups) { group in
                                HStack {
                                    Button {
                                        toggleGroupSelection(group.id)
                                    } label: {
                                        HStack {
                                            Image(systemName: selectedGroupIds.contains(group.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedGroupIds.contains(group.id) ? .blue : .gray)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(group.name)
                                                    .foregroundColor(.primary)
                                                if let description = group.description {
                                                    Text(description)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if selectedGroupIds.isEmpty {
                                Text("Select at least one group")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else {
                                Text("Selected \(selectedGroupIds.count) \(selectedGroupIds.count == 1 ? "group" : "groups")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Visibility")
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
                Text("Your tee time at \(displayCourseName) has been posted.")
            }
            .sheet(isPresented: $showCourseSearch) {
                GolfCourseSearchView(
                    selectedCourse: $selectedGolfCourse,
                    manualCourseName: $manualCourseName
                )
            }
            .task {
                await loadGroups()
            }
            .onChange(of: isPublic) { _, newValue in
                if !newValue {
                    Task {
                        await loadGroups()
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var displayCourseName: String {
        if let course = selectedGolfCourse {
            return course.name
        } else if !manualCourseName.isEmpty {
            return manualCourseName
        } else {
            return ""
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        let hasCourse = selectedGolfCourse != nil || !manualCourseName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasValidVisibility = isPublic || !selectedGroupIds.isEmpty
        return hasCourse && hasValidVisibility
    }

    // MARK: - Private Methods

    private func loadGroups() async {
        isLoadingGroups = true
        do {
            availableGroups = try await groupService.getGroups()
        } catch {
            // Silently fail - user will see empty state
        }
        isLoadingGroups = false
    }

    private func toggleGroupSelection(_ groupId: Int) {
        if selectedGroupIds.contains(groupId) {
            selectedGroupIds.remove(groupId)
        } else {
            selectedGroupIds.insert(groupId)
        }
    }

    private func createTeeTime() async {
        isCreating = true
        errorMessage = nil

        do {
            let groupIds = isPublic ? [] : Array(selectedGroupIds)

            // Determine course name and ID
            let courseName: String
            let golfCourseId: Int?

            if let course = selectedGolfCourse {
                courseName = course.name
                golfCourseId = course.id
            } else {
                courseName = manualCourseName.trimmingCharacters(in: .whitespaces)
                golfCourseId = nil
            }

            let _ = try await teeTimeService.createTeeTimePosting(
                courseName: courseName,
                teeTime: teeTime,
                totalSpots: totalSpots,
                initialReservationSpots: reserveForMyself > 0 ? reserveForMyself : nil,
                notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
                groupIds: groupIds,
                golfCourseId: golfCourseId
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
