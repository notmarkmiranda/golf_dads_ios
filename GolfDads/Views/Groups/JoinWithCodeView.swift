//
//  JoinWithCodeView.swift
//  GolfDads
//
//  View for joining a group using an invite code
//

import SwiftUI

struct JoinWithCodeView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss

    @State private var inviteCode: String = ""
    @State private var isJoining = false
    @State private var errorMessage: String?

    private let groupService: GroupServiceProtocol
    private let onGroupJoined: (Group) -> Void

    // MARK: - Initialization

    init(
        groupService: GroupServiceProtocol = GroupService(),
        onGroupJoined: @escaping (Group) -> Void
    ) {
        self.groupService = groupService
        self.onGroupJoined = onGroupJoined
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Invite Code", text: $inviteCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                } header: {
                    Text("Join Group")
                } footer: {
                    Text("Enter the 8-character invite code shared by a group owner")
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Join with Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isJoining)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Join") {
                        Task {
                            await joinGroup()
                        }
                    }
                    .disabled(inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isJoining)
                }
            }
            .disabled(isJoining)
        }
    }

    // MARK: - Methods

    private func joinGroup() async {
        let trimmedCode = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedCode.isEmpty else {
            errorMessage = "Invite code is required"
            return
        }

        isJoining = true
        errorMessage = nil

        do {
            let group = try await groupService.joinWithInviteCode(trimmedCode)

            onGroupJoined(group)
            dismiss()
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.userMessage
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isJoining = false
    }
}

// MARK: - Preview

#Preview {
    JoinWithCodeView { _ in }
}
