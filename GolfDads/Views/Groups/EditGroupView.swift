//
//  EditGroupView.swift
//  GolfDads
//
//  View for editing group name and description
//

import SwiftUI

struct EditGroupView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss

    let group: Group
    let onSave: (String, String?) -> Void

    @State private var name: String
    @State private var description: String

    // MARK: - Initialization

    init(group: Group, onSave: @escaping (String, String?) -> Void) {
        self.group = group
        self.onSave = onSave
        self._name = State(initialValue: group.name)
        self._description = State(initialValue: group.description ?? "")
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                Section("Group Name") {
                    TextField("Name", text: $name)
                }

                Section("Description (Optional)") {
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedDesc = description.trimmingCharacters(in: .whitespaces)
                        onSave(name, trimmedDesc.isEmpty ? nil : trimmedDesc)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EditGroupView(
        group: Group(
            id: 1,
            name: "Weekend Warriors",
            description: "Saturday morning golf group",
            ownerId: 1,
            inviteCode: "ABC12XYZ",
            memberNames: ["john@example.com", "jane@example.com"],
            createdAt: Date(),
            updatedAt: Date()
        )
    ) { name, description in
        print("Save: \(name), \(description ?? "nil")")
    }
}
