//
//  MyTeeTimesView.swift
//  GolfDads
//
//  Display and manage user's tee time postings
//

import SwiftUI

struct MyTeeTimesView: View {

    @State private var teeTimePostings: [TeeTimePosting] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCreateSheet = false
    @State private var postingToDelete: TeeTimePosting?
    @State private var showDeleteAlert = false

    private let teeTimeService: TeeTimeServiceProtocol

    init(teeTimeService: TeeTimeServiceProtocol = TeeTimeService()) {
        self.teeTimeService = teeTimeService
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
                                await loadMyTeeTimePostings()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if teeTimePostings.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.3))

                        Text("No Tee Times Yet")
                            .font(.title2)
                            .fontWeight(.medium)

                        Text("Create your first tee time posting to get started")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            showCreateSheet = true
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
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await loadMyTeeTimePostings()
                    }
                }
            }
            .navigationTitle("My Tee Times")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateSheet = true
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
            .task {
                await loadMyTeeTimePostings()
            }
            .onChange(of: showCreateSheet) { _, newValue in
                // Reload when create sheet is dismissed
                if !newValue {
                    Task {
                        await loadMyTeeTimePostings()
                    }
                }
            }
        }
    }

    // MARK: - Private Methods

    private func loadMyTeeTimePostings() async {
        isLoading = true
        errorMessage = nil

        do {
            teeTimePostings = try await teeTimeService.getMyTeeTimePostings()
        } catch {
            errorMessage = "Failed to load tee times: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func deleteTeeTime(_ posting: TeeTimePosting) async {
        do {
            try await teeTimeService.deleteTeeTimePosting(id: posting.id)
            // Remove from list
            teeTimePostings.removeAll { $0.id == posting.id }
            postingToDelete = nil
        } catch {
            errorMessage = "Failed to delete tee time: \(error.localizedDescription)"
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

#Preview {
    MyTeeTimesView()
}
