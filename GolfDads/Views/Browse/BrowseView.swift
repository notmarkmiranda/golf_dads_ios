//
//  BrowseView.swift
//  GolfDads
//
//  Browse and discover public tee time postings
//

import SwiftUI
import CoreLocation

struct BrowseView: View {

    @StateObject private var locationManager = LocationManager()
    @State private var teeTimePostings: [TeeTimePosting] = []
    @State private var userGroups: [Group] = []
    @State private var myReservations: [Reservation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Location filter state
    @State private var filterMode: LocationFilterMode = .all
    @State private var manualZipCode: String = ""
    @State private var radiusMiles: Int = 25
    @State private var showFilterSheet = false
    @State private var hasLoadedPreferences = false

    private let teeTimeService: TeeTimeServiceProtocol
    private let groupService: GroupServiceProtocol
    private let reservationService: ReservationServiceProtocol
    let authManager: AuthenticationManager

    init(
        authManager: AuthenticationManager,
        teeTimeService: TeeTimeServiceProtocol = TeeTimeService(),
        groupService: GroupServiceProtocol = GroupService(),
        reservationService: ReservationServiceProtocol = ReservationService()
    ) {
        self.authManager = authManager
        self.teeTimeService = teeTimeService
        self.groupService = groupService
        self.reservationService = reservationService
    }

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading tee times...")
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)

                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)

                        Button("Try Again") {
                            Task {
                                await loadTeeTimePostings()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if teeTimePostings.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "flag")
                            .font(.system(size: 50))
                            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.3))

                        Text("No Available Tee Times")
                            .font(.title2)
                            .fontWeight(.medium)

                        Text("Check back later for tee times in your groups")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(teeTimePostings) { posting in
                        NavigationLink(destination: TeeTimeDetailView(posting: posting)) {
                            TeeTimePostingRow(posting: posting, showDistance: filterMode == .nearby)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await loadTeeTimePostings()
                    }
                }
            }
            .navigationTitle("Available Tee Times")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showFilterSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(filterMode.rawValue)
                                .font(.subheadline)
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await loadTeeTimePostings()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                LocationFilterSheet(
                    locationManager: locationManager,
                    filterMode: $filterMode,
                    manualZipCode: $manualZipCode,
                    radiusMiles: $radiusMiles
                )
            }
            .onChange(of: filterMode) { _, _ in
                Task {
                    await loadTeeTimePostings()
                }
            }
            .onChange(of: manualZipCode) { _, _ in
                // Only reload if in nearby mode and zip code changed
                if filterMode == .nearby {
                    Task {
                        await loadTeeTimePostings()
                    }
                }
            }
            .task {
                // Load user preferences on first appear
                if !hasLoadedPreferences {
                    loadLocationPreferences()
                    hasLoadedPreferences = true
                }
                await loadTeeTimePostings()
            }
        }
    }

    // MARK: - Private Methods

    private func loadLocationPreferences() {
        guard let user = authManager.currentUser else { return }

        // Load saved zip code preference
        if let zipCode = user.homeZipCode, !zipCode.isEmpty {
            manualZipCode = zipCode
        }

        // Load saved radius preference (defaults to 25 if not set)
        radiusMiles = user.preferredRadiusMiles ?? 25
    }

    private func loadTeeTimePostings() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load user's groups and reservations
            userGroups = try await groupService.getGroups()
            myReservations = try await reservationService.getMyReservations()

            // If user has no groups, show empty state
            guard !userGroups.isEmpty else {
                teeTimePostings = []
                isLoading = false
                return
            }

            // Fetch tee times from all user's groups
            var allGroupTeeTimes: [TeeTimePosting] = []
            for group in userGroups {
                let groupPostings = try await teeTimeService.getGroupTeeTimePostings(groupId: group.id)
                allGroupTeeTimes.append(contentsOf: groupPostings)
            }

            // Get current user ID
            guard let currentUserId = authManager.currentUser?.id else {
                teeTimePostings = []
                isLoading = false
                return
            }

            // Get set of posting IDs where user has reservations
            let reservedPostingIds = Set(myReservations.map { $0.teeTimePosting?.id }.compactMap { $0 })

            // Filter: exclude tee times where user is owner or has reservation
            teeTimePostings = allGroupTeeTimes.filter { posting in
                posting.userId != currentUserId && !reservedPostingIds.contains(posting.id)
            }

            // Remove duplicates (same posting in multiple groups)
            var seen = Set<Int>()
            teeTimePostings = teeTimePostings.filter { posting in
                guard !seen.contains(posting.id) else { return false }
                seen.insert(posting.id)
                return true
            }

            // Sort by tee time
            teeTimePostings.sort { $0.teeTime < $1.teeTime }

        } catch {
            errorMessage = "Failed to load tee times: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func getCoordinates() async throws -> CLLocationCoordinate2D {
        // If manual zip code is provided, use that
        if !manualZipCode.isEmpty {
            return try await locationManager.geocodeZipCode(manualZipCode)
        }

        // Otherwise, get device location
        return try await locationManager.getCurrentLocation()
    }
}

// MARK: - Tee Time Posting Row

struct TeeTimePostingRow: View {
    let posting: TeeTimePosting
    var showDistance: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(posting.displayCourseName)
                    .font(.headline)

                Spacer()

                if posting.isPublic {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                        .font(.caption)
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }

            // Golf course location (if available)
            if let golfCourse = posting.golfCourse, !golfCourse.displayLocation.isEmpty {
                HStack {
                    Image(systemName: "mappin.circle")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    Text(golfCourse.displayLocation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Distance (if available and requested)
            if showDistance, let distance = posting.distanceMiles {
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    Text(String(format: "%.1f miles away", distance))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                    .font(.caption)

                Text(posting.teeTime, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(posting.teeTime, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Image(systemName: "person.2")
                    .foregroundColor(.secondary)
                    .font(.caption)

                Text("\(posting.availableSpots) spots available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let totalSpots = posting.totalSpots {
                    Text("of \(totalSpots)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if let notes = posting.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            if posting.isPast {
                Text("Past")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BrowseView(authManager: AuthenticationManager())
}
