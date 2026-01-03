//
//  MyTeeTimesView.swift
//  GolfDads
//
//  Display and manage user's tee time postings
//

import SwiftUI

struct MyTeeTimesView: View {

    @State private var teeTimePostings: [TeeTimePosting] = []
    @State private var myReservations: [Reservation] = []
    @State private var userGroups: [Group] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCreateSheet = false
    @State private var postingToDelete: TeeTimePosting?
    @State private var showDeleteAlert = false
    @State private var showNoGroupsAlert = false
    @State private var currentLoadTask: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss

    private let teeTimeService: TeeTimeServiceProtocol
    private let reservationService: ReservationServiceProtocol
    private let groupService: GroupServiceProtocol

    // Calendar integration
    @StateObject private var calendarSyncManager = CalendarSyncManager()

    init(
        teeTimeService: TeeTimeServiceProtocol = TeeTimeService(),
        reservationService: ReservationServiceProtocol = ReservationService(),
        groupService: GroupServiceProtocol = GroupService()
    ) {
        self.teeTimeService = teeTimeService
        self.reservationService = reservationService
        self.groupService = groupService
    }

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading your tee times...")
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
                                await loadData()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if teeTimePostings.isEmpty && myReservations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.3))

                        Text("No Tee Times Yet")
                            .font(.title2)
                            .fontWeight(.medium)

                        Text("Create or join a group to get started")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            handleCreateTeeTimeButtonTap()
                        } label: {
                            Label("Create Tee Time", systemImage: "plus")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()
                } else {
                    List {
                        // My Postings Section
                        if !teeTimePostings.isEmpty {
                            Section {
                                ForEach(teeTimePostings) { posting in
                                    NavigationLink(destination: TeeTimeDetailView(posting: posting)) {
                                        MyTeeTimeRow(posting: posting)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            postingToDelete = posting
                                            showDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                Text("My Postings")
                            }
                        }

                        // My Reservations Section
                        if !myReservations.isEmpty {
                            Section {
                                ForEach(myReservations) { reservation in
                                    if let posting = reservation.teeTimePosting {
                                        NavigationLink(destination: TeeTimeDetailView(posting: createTeeTimePosting(from: reservation))) {
                                            MyReservationRow(reservation: reservation, posting: posting)
                                        }
                                    }
                                }
                            } header: {
                                Text("My Reservations")
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Tee Times")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        handleCreateTeeTimeButtonTap()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateTeeTimeView()
            }
            .alert("Delete Tee Time?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    postingToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let posting = postingToDelete {
                        Task {
                            await deleteTeeTime(posting)
                        }
                    }
                }
            } message: {
                if let posting = postingToDelete {
                    Text("Are you sure you want to delete the tee time at \(posting.courseName)?")
                }
            }
            .alert("Join or Create a Group", isPresented: $showNoGroupsAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("You need to join or create a group before you can post tee times. Visit the Groups tab to get started.")
            }
            .task(id: "loadData") {
                startLoadData()
            }
            .refreshable {
                // Cancel existing task and start new one
                currentLoadTask?.cancel()
                await loadData()
            }
            .onChange(of: showCreateSheet) { _, newValue in
                // Reload when create sheet is dismissed
                if !newValue {
                    startLoadData()
                }
            }
        }
    }

    // MARK: - Private Methods

    private func startLoadData() {
        // Cancel any existing load task
        currentLoadTask?.cancel()

        // Start a new load task
        currentLoadTask = Task {
            await loadData()
        }
    }

    @MainActor
    private func loadData() async {
        // Prevent concurrent loads
        guard !isLoading else {
            print("⚠️ Load already in progress, skipping")
            return
        }

        isLoading = true
        errorMessage = nil

        // Track whether we had actual errors (not just empty results)
        var hadError = false

        async let postingsResult: [TeeTimePosting] = {
            do {
                return try await self.teeTimeService.getMyTeeTimePostings()
            } catch is CancellationError {
                print("⚠️ Postings request was cancelled")
                return []
            } catch let error as APIError {
                // Check if it's a URLError with code -999 (cancelled)
                if case .unknown(let underlyingError) = error,
                   let urlError = underlyingError as? URLError,
                   urlError.code == .cancelled {
                    print("⚠️ Postings request was cancelled (URLError -999)")
                    return []
                }
                print("❌ Failed to load postings: \(error)")
                hadError = true
                return []
            } catch {
                print("❌ Failed to load postings: \(error)")
                hadError = true
                return []
            }
        }()

        async let reservationsResult: [Reservation] = {
            do {
                let reservations = try await self.reservationService.getMyReservations()
                print("🔍 MyTeeTimesView: Loaded \(reservations.count) reservations")
                for reservation in reservations {
                    print("  - Reservation \(reservation.id): \(reservation.spotsReserved) spots")
                    if let posting = reservation.teeTimePosting {
                        print("    ✅ Has teeTimePosting: \(posting.courseName)")
                    } else {
                        print("    ❌ Missing teeTimePosting")
                    }
                }
                return reservations
            } catch is CancellationError {
                print("⚠️ Reservations request was cancelled")
                return []
            } catch let error as APIError {
                // Check if it's a URLError with code -999 (cancelled)
                if case .unknown(let underlyingError) = error,
                   let urlError = underlyingError as? URLError,
                   urlError.code == .cancelled {
                    print("⚠️ Reservations request was cancelled (URLError -999)")
                    return []
                }
                print("❌ Failed to load reservations: \(error)")
                hadError = true
                return []
            } catch {
                print("❌ Failed to load reservations: \(error)")
                hadError = true
                return []
            }
        }()

        async let groupsResult: [Group] = {
            do {
                return try await self.groupService.getGroups()
            } catch {
                print("⚠️ Failed to load groups: \(error)")
                return []
            }
        }()

        let newPostings = await postingsResult
        let newReservations = await reservationsResult
        let newGroups = await groupsResult

        // Update groups
        userGroups = newGroups

        // Get IDs of postings where user has a reservation
        let postingIdsWithReservations = Set(newReservations.compactMap { $0.teeTimePosting?.id })

        // Only update if we got results OR if we currently have no data
        // This prevents clearing data on cancelled refreshes
        if !newPostings.isEmpty || teeTimePostings.isEmpty {
            // Filter out postings where the user has a reservation
            // (those should appear in "My Reservations" instead)
            teeTimePostings = newPostings.filter { !postingIdsWithReservations.contains($0.id) }
        }
        if !newReservations.isEmpty || myReservations.isEmpty {
            // Keep all reservations - even if user owns the posting
            // If they reserved spots on their own posting, show it in reservations
            myReservations = newReservations
        }

        print("📊 Final state: \(teeTimePostings.count) postings, \(myReservations.count) reservations")

        // Only set error message if we had actual errors (not just empty results from a fresh database)
        if hadError && teeTimePostings.isEmpty && myReservations.isEmpty {
            errorMessage = "Failed to load tee times. Please try again."
        }

        // Auto-sync: Check for changes and update calendar events
        // Use filtered list for syncing (only sync what's displayed in "My Postings")
        await calendarSyncManager.syncAllReservations(myReservations)
        await calendarSyncManager.syncAllPostings(teeTimePostings)

        // Cleanup deleted events
        // Pass UNFILTERED postings list so cleanup knows about ALL user's postings
        await calendarSyncManager.cleanupDeletedEvents(
            currentReservations: myReservations,
            currentPostings: newPostings  // Use unfiltered list!
        )

        isLoading = false
    }

    private func createTeeTimePosting(from reservation: Reservation) -> TeeTimePosting {
        guard let posting = reservation.teeTimePosting else {
            fatalError("Reservation should have posting info")
        }

        return TeeTimePosting(
            id: posting.id,
            userId: reservation.userId,
            groupIds: [],
            teeTime: posting.teeTime,
            courseName: posting.courseName,
            golfCourse: nil,
            distanceMiles: nil,
            availableSpots: posting.availableSpots,
            totalSpots: posting.totalSpots,
            notes: posting.notes,
            reservations: nil,
            createdAt: reservation.createdAt,
            updatedAt: reservation.updatedAt
        )
    }

    private func deleteTeeTime(_ posting: TeeTimePosting) async {
        do {
            try await teeTimeService.deleteTeeTimePosting(id: posting.id)

            // Remove from calendar
            await calendarSyncManager.removePosting(postingId: posting.id)

            // Remove from list
            teeTimePostings.removeAll { $0.id == posting.id }
            postingToDelete = nil
        } catch {
            errorMessage = "Failed to delete tee time: \(error.localizedDescription)"
        }
    }

    private func handleCreateTeeTimeButtonTap() {
        if userGroups.isEmpty {
            showNoGroupsAlert = true
        } else {
            showCreateSheet = true
        }
    }
}

// MARK: - My Tee Time Row

struct MyTeeTimeRow: View {
    let posting: TeeTimePosting

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(posting.courseName)
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

// MARK: - My Reservation Row

struct MyReservationRow: View {
    let reservation: Reservation
    let posting: ReservationTeeTimeInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(posting.courseName)
                    .font(.headline)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)

                    Text("\(reservation.spotsReserved) \(reservation.spotsReserved == 1 ? "spot" : "spots")")
                        .font(.caption)
                        .foregroundColor(.green)
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
    MyTeeTimesView()
}
