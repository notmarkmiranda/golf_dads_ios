//
//  AppIconGenerator.swift
//  GolfDads
//
//  Utility for generating app icon from SwiftUI view
//

import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Gradient background - golf course greens
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.6, blue: 0.3),  // Darker green
                    Color(red: 0.3, green: 0.7, blue: 0.4)   // Lighter green
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Golf flag icon
            VStack(spacing: 20) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 140, weight: .regular))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

                // Three dots representing "dads" / community
                HStack(spacing: 16) {
                    Circle()
                        .fill(.white)
                        .frame(width: 22, height: 22)

                    Circle()
                        .fill(.white)
                        .frame(width: 22, height: 22)

                    Circle()
                        .fill(.white)
                        .frame(width: 22, height: 22)
                }
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AppIconView()
        .frame(width: 1024, height: 1024)
        .clipShape(RoundedRectangle(cornerRadius: 225)) // iOS icon corner radius at 1024px
}

// MARK: - Icon Generator Helper
extension AppIconView {
    /// Renders the icon view to a UIImage
    @MainActor
    func renderAsImage(size: CGSize) -> UIImage? {
        let renderer = ImageRenderer(content: self.frame(width: size.width, height: size.height))
        renderer.scale = 1.0 // Use 1.0 for high resolution
        return renderer.uiImage
    }
}

// MARK: - Usage Instructions
/*
 To generate your app icon:

 1. Open this file in Xcode
 2. Click the "Preview" button to see the icon
 3. Take a screenshot or use the code below to export

 To export programmatically:

 ```swift
 let iconView = AppIconView()
 if let image = iconView.renderAsImage(size: CGSize(width: 1024, height: 1024)) {
     // Save to Files app or Photos
     if let data = image.pngData() {
         try? data.write(to: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("AppIcon.png"))
     }
 }
 ```

 Required sizes for iOS app icons:
 - 1024x1024 (App Store)
 - 180x180 (@3x iPhone)
 - 120x120 (@2x iPhone)
 - 167x167 (@2x iPad Pro)
 - 152x152 (@2x iPad)
 - 76x76 (@1x iPad)

 You can use https://www.appicon.co to generate all sizes from the 1024x1024 version.
 */
