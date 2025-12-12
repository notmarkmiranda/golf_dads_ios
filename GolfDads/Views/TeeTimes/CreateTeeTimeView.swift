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
    @State private var hasInitializedVisibility = false

    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false

    // Calendar integration
    @StateObject private var calendarSyncManager = CalendarSyncManager()
    @State private var showCalendarPrompt = false
    @State private var createdPosting: TeeTimePosting?
    @State private var showCalendarResultAlert = false
    @State private var calendarResultMessage = ""
    @State private var recentFavorites: [GolfCourse] = []
    @State private var showFavorites = false

    private let teeTimeService: TeeTimeServiceProtocol
    private let groupService: GroupServiceProtocol
    private let favoriteService: FavoriteCourseServiceProtocol

    let preselectedCourse: GolfCourse?

    init(
        preselectedCourse: GolfCourse? = nil,
        teeTimeService: TeeTimeServiceProtocol = TeeTimeService(),
        groupService: GroupServiceProtocol = GroupService(),
        favoriteService: FavoriteCourseServiceProtocol = FavoriteCourseService()
    ) {
        self.preselectedCourse = preselectedCourse
        self.teeTimeService = teeTimeService
        self.groupService = groupService
        self.favoriteService = favoriteService
    }

    var body: some View {
        NavigationView {
            Form {
                // Course Information
                Section("Course Information") {
                    if selectedGolfCourse != nil || !manualCourseName.isEmpty {
                        // Show selected course
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
                                    }
                                }

                                Spacer()

                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        // Show search button
                        Button {
                            showCourseSearch = true
                        } label: {
                            Label("Search for Course", systemImage: "magnifyingglass")
                        }

                        // Show recent favorites for quick access
                        if !recentFavorites.isEmpty {
                            ForEach(recentFavorites.prefix(3), id: \.id) { course in
                                Button {
                                    selectedGolfCourse = course
                                } label: {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundStyle(.yellow)
                                            .imageScale(.small)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(course.name)
                                                .foregroundColor(.primary)
                                            if !course.displayLocation.isEmpty {
                                                Text(course.displayLocation)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            }

                            Button("View All Favorites") {
                                showFavorites = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }

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
                    // If user reserved spots, show calendar prompt next
                    if createdPosting != nil {
                        showCalendarPrompt = true
                    } else {
                        dismiss()
                    }
                }
            } message: {
                Text("Your tee time at \(displayCourseName) has been posted.")
            }
            .alert("Add to Calendar?", isPresented: $showCalendarPrompt) {
                Button("Add to Calendar") {
                    Task {
                        if let posting = createdPosting {
                            print("🔵 Starting calendar sync for posting \(posting.id)")
                            let success = await calendarSyncManager.syncPosting(posting, shouldPromptUser: true)
                            if success {
                                calendarResultMessage = "✅ Tee time added to your calendar!"
                                print("✅ Calendar sync succeeded")
                            } else {
                                calendarResultMessage = "❌ Failed to add to calendar. Please check calendar permissions in Settings."
                                print("❌ Calendar sync failed")
                            }
                            showCalendarResultAlert = true
                        }
                        createdPosting = nil
                    }
                }
                Button("Not Now", role: .cancel) {
                    createdPosting = nil
                    dismiss()
                }
            } message: {
                Text("Would you like to add this tee time to your calendar? It will automatically update if the time changes.")
            }
            .alert("Calendar", isPresented: $showCalendarResultAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(calendarResultMessage)
            }
            .sheet(isPresented: $showCourseSearch) {
                GolfCourseSearchView(
                    selectedCourse: $selectedGolfCourse,
                    manualCourseName: $manualCourseName
                )
            }
            .sheet(isPresented: $showFavorites) {
                FavoriteCoursesView()
            }
            .task {
                await loadGroups()
                await loadRecentFavorites()

                // Set preselected course if provided
                if let preselected = preselectedCourse {
                    selectedGolfCourse = preselected
                }
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

            // On first load, if user has groups, default to private and select all groups
            if !hasInitializedVisibility && !availableGroups.isEmpty {
                isPublic = false
                selectedGroupIds = Set(availableGroups.map { $0.id })
                hasInitializedVisibility = true
            }
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

            let posting = try await teeTimeService.createTeeTimePosting(
                courseName: courseName,
                teeTime: teeTime,
                totalSpots: totalSpots,
                initialReservationSpots: reserveForMyself > 0 ? reserveForMyself : nil,
                notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
                groupIds: groupIds,
                golfCourseId: golfCourseId
            )

            // Store posting if user reserved spots for themselves
            // Calendar prompt will show after success alert is dismissed
            if reserveForMyself > 0 {
                createdPosting = posting
            }

            showSuccessAlert = true
        } catch {
            errorMessage = "Failed to create tee time: \(error.localizedDescription)"
        }

        isCreating = false
    }

    private func loadRecentFavorites() async {
        do {
            let favorites = try await favoriteService.getFavorites()
            recentFavorites = Array(favorites.prefix(3))
        } catch {
            // Silently fail - favorites are optional convenience
            recentFavorites = []
        }
    }
}

#Preview {
    CreateTeeTimeView()
}
