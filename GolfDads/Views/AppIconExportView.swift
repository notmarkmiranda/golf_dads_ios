//
//  AppIconExportView.swift
//  GolfDads
//
//  Simple view to preview and export the app icon
//

import SwiftUI

struct AppIconExportView: View {
    @State private var showingSaved = false

    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Text("Golf Dads App Icon")
                    .font(.title)
                    .bold()

                // Icon preview
                AppIconView()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 44))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)

                VStack(spacing: 16) {
                    Text("Icon Design")
                        .font(.headline)

                    Text("Golf flag on a green gradient background with three dots representing community/friends")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button(action: saveIcon) {
                    Label("Save Icon to Files", systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if showingSaved {
                    Text("✓ Saved to Files app!")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Steps:")
                        .font(.headline)
                    Text("1. Use appicon.co to generate all required sizes")
                    Text("2. Replace the AppIcon in Assets.xcassets")
                    Text("3. Rebuild the app")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func saveIcon() {
        Task { @MainActor in
            let iconView = AppIconView()
            if let image = iconView.renderAsImage(size: CGSize(width: 1024, height: 1024)) {
                if let data = image.pngData() {
                    let filename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent("GolfDads_AppIcon_1024x1024.png")

                    try? data.write(to: filename)
                    print("✅ Icon saved to: \(filename.path)")

                    showingSaved = true

                    // Hide message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showingSaved = false
                    }
                }
            }
        }
    }
}

#Preview {
    AppIconExportView()
}
