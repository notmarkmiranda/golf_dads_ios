//
//  InvitationsView.swift
//  GolfDads
//
//  View for displaying and managing group invitations
//

import SwiftUI

struct InvitationsView: View {

    @State private var invitations: [GroupInvitation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var processingInvitationId: Int?
    @State private var showSuccessAlert = false
    @State private var successMessage: String?

    private let invitationService: GroupInvitationServiceProtocol

    init(invitationService: GroupInvitationServiceProtocol = GroupInvitationService()) {
        self.invitationService = invitationService
    }

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading invitations...")
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
                                await loadInvitations()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if invitations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "envelope")
                            .font(.system(size: 50))
                            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.3))

                        Text("No Pending Invitations")
                            .font(.title2)
                            .fontWeight(.medium)

                        Text("You don't have any group invitations at the moment")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(invitations) { invitation in
                            InvitationRow(
                                invitation: invitation,
                                isProcessing: processingInvitationId == invitation.id,
                                onAccept: {
                                    Task {
                                        await acceptInvitation(invitation)
                                    }
                                },
                                onReject: {
                                    Task {
                                        await rejectInvitation(invitation)
                                    }
                                }
                            )
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await loadInvitations()
                    }
                }
            }
            .navigationTitle("Group Invitations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await loadInvitations()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .task {
                await loadInvitations()
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let successMessage = successMessage {
                    Text(successMessage)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func loadInvitations() async {
        isLoading = true
        errorMessage = nil

        do {
            invitations = try await invitationService.getMyInvitations()
            // Filter to show only pending invitations
            invitations = invitations.filter { $0.isPending }
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.userMessage
            } else {
                errorMessage = "Failed to load invitations: \(error.localizedDescription)"
            }
        }

        isLoading = false
    }

    private func acceptInvitation(_ invitation: GroupInvitation) async {
        processingInvitationId = invitation.id

        do {
            _ = try await invitationService.acceptInvitation(id: invitation.id)
            successMessage = "You've joined the group!"
            showSuccessAlert = true
            // Remove the accepted invitation from the list
            invitations.removeAll { $0.id == invitation.id }
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.userMessage
            } else {
                errorMessage = "Failed to accept invitation: \(error.localizedDescription)"
            }
        }

        processingInvitationId = nil
    }

    private func rejectInvitation(_ invitation: GroupInvitation) async {
        processingInvitationId = invitation.id

        do {
            _ = try await invitationService.rejectInvitation(id: invitation.id)
            // Remove the rejected invitation from the list
            invitations.removeAll { $0.id == invitation.id }
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.userMessage
            } else {
                errorMessage = "Failed to reject invitation: \(error.localizedDescription)"
            }
        }

        processingInvitationId = nil
    }
}

// MARK: - Invitation Row

struct InvitationRow: View {
    let invitation: GroupInvitation
    let isProcessing: Bool
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "envelope.badge")
                        .foregroundColor(.blue)
                        .font(.caption)

                    Text("Group Invitation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(invitation.inviteeEmail)
                    .font(.headline)

                Text("Invited \(invitation.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if isProcessing {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                    Spacer()
                }
            } else {
                HStack(spacing: 12) {
                    Button {
                        onAccept()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Accept")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button {
                        onReject()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Decline")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    InvitationsView()
}
