//
//  GolfCourseSearchView.swift
//  GolfDads
//
//  Search for golf courses with real-time autocomplete
//

import SwiftUI
import CoreLocation

enum SearchMode: String, CaseIterable {
    case search = "Search"
    case nearby = "Nearby"
}

struct GolfCourseSearchView: View {

    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCourse: GolfCourse?
    @Binding var manualCourseName: String

    @StateObject private var locationManager = LocationManager()
    @State private var searchText: String = ""
    @State private var searchMode: SearchMode = .search
    @State private var searchResults: [GolfCourse] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?
    @State private var radiusMiles: Int = 25

    private let golfCourseService: GolfCourseServiceProtocol

    init(
        selectedCourse: Binding<GolfCourse?>,
        manualCourseName: Binding<String>,
        golfCourseService: GolfCourseServiceProtocol = GolfCourseService()
    ) {
        self._selectedCourse = selectedCourse
        self._manualCourseName = manualCourseName
        self.golfCourseService = golfCourseService
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Mode Picker
                Picker("Search Mode", selection: $searchMode) {
                    ForEach(SearchMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if searchMode == .search {
                    searchModeView
                } else {
                    nearbyModeView
                }
            }
            .navigationTitle("Find Golf Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: searchMode) { _, _ in
                // Clear results when switching modes
                searchResults = []
                errorMessage = nil
            }
            .onChange(of: searchText) { _, newValue in
                handleSearchTextChange(newValue)
            }
        }
    }

    // MARK: - Search Mode View

    private var searchModeView: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search golf courses...", text: $searchText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                if isSearching {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                } else if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            // Results List
            if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)

                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchText.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)

                    Text("Search for a golf course by name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Or enter a custom course name below")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchResults.isEmpty && !isSearching {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)

                    Text("No courses found for \"\(searchText)\"")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Manual entry option
                    Button {
                        selectManualEntry()
                    } label: {
                        HStack {
                            Image(systemName: "text.cursor")
                            Text("Use \"\(searchText)\" as manual entry")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    // Manual entry option at top when there are results
                    if !searchText.isEmpty {
                        Button {
                            selectManualEntry()
                        } label: {
                            HStack {
                                Image(systemName: "text.cursor")
                                    .foregroundColor(.blue)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Use \"\(searchText)\" as manual entry")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)

                                    Text("Won't have location data")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    ForEach(searchResults) { course in
                        Button {
                            Task {
                                await selectCourse(course)
                            }
                        } label: {
                            GolfCourseRow(course: course, showDistance: false)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Nearby Mode View

    private var nearbyModeView: some View {
        VStack(spacing: 0) {
            // Location Status
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: locationIcon)
                        .foregroundColor(locationIconColor)

                    Text(locationStatusText)
                        .font(.subheadline)

                    Spacer()

                    if locationManager.authorizationStatus == .notDetermined {
                        Button("Allow") {
                            Task {
                                do {
                                    try await locationManager.requestPermission()
                                    await loadNearbyCourses()
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }

                // Radius Slider
                HStack {
                    Text("Radius:")
                        .font(.subheadline)

                    Slider(value: Binding(
                        get: { Double(radiusMiles) },
                        set: { radiusMiles = Int($0) }
                    ), in: 5...100, step: 5)

                    Text("\(radiusMiles) mi")
                        .font(.subheadline)
                        .frame(width: 50, alignment: .trailing)
                }

                if locationManager.authorizationStatus == .authorizedWhenInUse ||
                   locationManager.authorizationStatus == .authorizedAlways {
                    Button {
                        Task {
                            await loadNearbyCourses()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Search Nearby")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isSearching)
                }
            }
            .padding()
            .background(Color(.systemGray6))

            Divider()

            // Results List
            if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)

                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    if locationManager.authorizationStatus == .denied {
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchResults.isEmpty && !isSearching {
                VStack(spacing: 16) {
                    Image(systemName: "location.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)

                    if locationManager.authorizationStatus == .authorizedWhenInUse ||
                       locationManager.authorizationStatus == .authorizedAlways {
                        Text("Tap 'Search Nearby' to find courses near you")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Allow location access to find nearby courses")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isSearching {
                ProgressView("Searching nearby courses...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(searchResults) { course in
                    Button {
                        Task {
                            await selectCourse(course)
                        }
                    } label: {
                        GolfCourseRow(course: course, showDistance: true)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Location Status Helpers

    private var locationIcon: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "location.circle"
        case .authorizedWhenInUse, .authorizedAlways:
            return "location.fill"
        case .denied, .restricted:
            return "location.slash"
        @unknown default:
            return "location.circle"
        }
    }

    private var locationIconColor: Color {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return .orange
        case .authorizedWhenInUse, .authorizedAlways:
            return .green
        case .denied, .restricted:
            return .red
        @unknown default:
            return .secondary
        }
    }

    private var locationStatusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Location permission not set"
        case .authorizedWhenInUse, .authorizedAlways:
            return "Location access granted"
        case .denied:
            return "Location access denied"
        case .restricted:
            return "Location access restricted"
        @unknown default:
            return "Location status unknown"
        }
    }

    // MARK: - Search Logic

    private func handleSearchTextChange(_ newValue: String) {
        // Cancel previous search task
        searchTask?.cancel()

        // Clear results if search text is empty
        guard !newValue.isEmpty else {
            searchResults = []
            errorMessage = nil
            return
        }

        // Require at least 2 characters
        guard newValue.count >= 2 else {
            searchResults = []
            return
        }

        // Debounce: wait 300ms after user stops typing
        searchTask = Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // 300ms

                guard !Task.isCancelled else { return }

                await performSearch(query: newValue)
            } catch {
                // Task was cancelled or sleep failed
            }
        }
    }

    private func performSearch(query: String) async {
        isSearching = true
        errorMessage = nil

        do {
            let results = try await golfCourseService.search(query: query)
            guard !Task.isCancelled else { return }
            searchResults = results
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = "Search failed: \(error.localizedDescription)"
            searchResults = []
        }

        isSearching = false
    }

    private func loadNearbyCourses() async {
        isSearching = true
        errorMessage = nil

        do {
            let coordinates = try await locationManager.getCurrentLocation()
            let results = try await golfCourseService.getNearby(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude,
                radius: radiusMiles
            )
            searchResults = results
        } catch LocationError.permissionDenied {
            errorMessage = "Location permission denied. Please enable location services in Settings."
        } catch LocationError.locationUnavailable {
            errorMessage = "Unable to determine your location. Please try again."
        } catch LocationError.timeout {
            errorMessage = "Location request timed out. Please try again."
        } catch {
            errorMessage = "Failed to load nearby courses: \(error.localizedDescription)"
        }

        isSearching = false
    }

    // MARK: - Selection

    private func selectCourse(_ course: GolfCourse) async {
        // If course doesn't have an ID, it came from external API and needs to be cached
        if course.id == nil {
            do {
                let cachedCourse = try await golfCourseService.cacheCourse(course)
                selectedCourse = cachedCourse
            } catch {
                // If caching fails, still use the course but without database ID
                print("⚠️ Failed to cache course: \(error.localizedDescription)")
                selectedCourse = course
            }
        } else {
            // Course already exists in database
            selectedCourse = course
        }

        manualCourseName = "" // Clear manual name when course selected
        dismiss()
    }

    private func selectManualEntry() {
        manualCourseName = searchText.trimmingCharacters(in: .whitespaces)
        selectedCourse = nil // Clear selected course
        dismiss()
    }
}

// MARK: - Golf Course Row

struct GolfCourseRow: View {
    let course: GolfCourse
    var showDistance: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                if !course.displayLocation.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle")
                            .font(.caption)
                        Text(course.displayLocation)
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }

                if showDistance, let distance = course.distanceMiles {
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption)
                        Text(String(format: "%.1f miles away", distance))
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GolfCourseSearchView(
        selectedCourse: .constant(nil),
        manualCourseName: .constant("")
    )
}
