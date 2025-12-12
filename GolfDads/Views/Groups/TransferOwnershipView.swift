//
//  TransferOwnershipView.swift
//  GolfDads
//
//  View for transferring group ownership to another member
//

import SwiftUI

struct TransferOwnershipView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss

    let group: Group
    let members: [GroupMember]
    let onTransfer: (Int) -> Void

    @State private var selectedMemberId: Int?
    @State private var showConfirmation = false

    private var eligibleMembers: [GroupMember] {
        members.filter { $0.id != group.ownerId }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(eligibleMembers) { member in
                        Button {
                            selectedMemberId = member.id
                            showConfirmation = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(member.name)
                                        .foregroundStyle(.primary)
                                    Text(member.email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if selectedMemberId == member.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Select New Owner")
                } footer: {
                    Text("Transferring ownership cannot be undone unless the new owner transfers it back to you.")
                }
            }
            .navigationTitle("Transfer Ownership")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .confirmationDialog("Confirm Transfer", isPresented: $showConfirmation) {
                Button("Transfer Ownership", role: .destructive) {
                    if let memberId = selectedMemberId {
                        onTransfer(memberId)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let member = eligibleMembers.first(where: { $0.id == selectedMemberId }) {
                    Text("Are you sure you want to make \(member.name) the new owner? You will become a regular member.")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TransferOwnershipView(
        group: Group(
            id: 1,
            name: "Weekend Warriors",
            description: "Saturday morning golf group",
            ownerId: 1,
            inviteCode: "ABC12XYZ",
            memberNames: ["john@example.com", "jane@example.com"],
            createdAt: Date(),
            updatedAt: Date()
        ),
        members: [
            GroupMember(id: 1, email: "john@example.com", name: "john", joinedAt: Date()),
            GroupMember(id: 2, email: "jane@example.com", name: "jane", joinedAt: Date()),
            GroupMember(id: 3, email: "bob@example.com", name: "bob", joinedAt: Date())
        ]
    ) { newOwnerId in
        print("Transfer to: \(newOwnerId)")
    }
}
