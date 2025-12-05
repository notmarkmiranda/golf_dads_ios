//
//  BrowseView.swift
//  GolfDads
//
//  Browse and discover public tee time postings
//

import SwiftUI

struct BrowseView: View {

    @State private var teeTimePostings: [TeeTimePosting] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentUserId: Int?

    private let teeTimeService: TeeTimeServiceProtocol

    init(teeTimeService: TeeTimeServiceProtocol = TeeTimeService()) {
        self.teeTimeService = teeTimeService
    }

    var body: some View {
        NavigationView {
            ZStack {
                if currentUserId == nil {
                    ProgressView("Loading...")
                } else if isLoading {
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

                        Text("No Tee Times Available")
                            .font(.title2)
                            .fontWeight(.medium)

                        Text("Check back later for available tee times")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(teeTimePostings) { posting in
                        NavigationLink(destination: TeeTimeDetailView(posting: posting, currentUserId: currentUserId)) {
                            TeeTimePostingRow(posting: posting)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await loadTeeTimePostings()
                    }
                }
            }
            .navigationTitle("Browse Tee Times")
            .toolbar {
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
            .task {
                // Load user ID first, then tee times
                await loadCurrentUserId()
                await loadTeeTimePostings()
            }
            .onAppear {
                print("🔍 BrowseView appeared with currentUserId: \(String(describing: currentUserId))")
            }
        }
    }

    // MARK: - Private Methods

    private func loadCurrentUserId() async {
        print("🔍 BrowseView: Loading current user ID")
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

    private func loadTeeTimePostings() async {
        isLoading = true
        errorMessage = nil

        do {
            teeTimePostings = try await teeTimeService.getTeeTimePostings()
        } catch {
            errorMessage = "Failed to load tee times: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Tee Time Posting Row

struct TeeTimePostingRow: View {
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
    BrowseView()
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
