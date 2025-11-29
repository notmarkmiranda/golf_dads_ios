//
//  SendInvitationView.swift
//  GolfDads
//
//  View for sending group invitations
//

import SwiftUI

struct SendInvitationView: View {

    @Environment(\.dismiss) private var dismiss

    let group: Group

    @State private var inviteeEmail: String = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false

    private let invitationService: GroupInvitationServiceProtocol

    init(
        group: Group,
        invitationService: GroupInvitationServiceProtocol = GroupInvitationService()
    ) {
        self.group = group
        self.invitationService = invitationService
    }

    var body: some View {
        NavigationView {
            Form {
                // Group Information
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.name)
                            .font(.headline)

                        if let description = group.description {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Inviting to Group")
                }

                // Invitation Details
                Section {
                    TextField("Email Address", text: $inviteeEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)

                    Text("Enter the email address of the person you want to invite")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Invitee Information")
                }

                // Error Message
                if let error = errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)

                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }

                // Send Button
                Section {
                    Button {
                        Task {
                            await sendInvitation()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isSending {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Send Invitation")
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || isSending)
                }
            }
            .navigationTitle("Invite Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Invitation Sent", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your invitation has been sent to \(inviteeEmail)")
            }
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !inviteeEmail.isEmpty && inviteeEmail.contains("@")
    }

    // MARK: - Private Methods

    private func sendInvitation() async {
        isSending = true
        errorMessage = nil

        do {
            _ = try await invitationService.sendInvitation(
                groupId: group.id,
                inviteeEmail: inviteeEmail
            )
            showSuccessAlert = true
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.userMessage
            } else {
                errorMessage = "Failed to send invitation: \(error.localizedDescription)"
            }
        }

        isSending = false
    }
}

#Preview {
    SendInvitationView(
        group: Group(
            id: 1,
            name: "Weekend Warriors",
            description: "Saturday morning golf group",
            ownerId: 1,
            createdAt: Date(),
            updatedAt: Date()
        )
    )
}
