import SwiftUI
import CoreLocation

// MARK: - Location Filter Mode
enum LocationFilterMode: String, CaseIterable {
    case all = "All"
    case nearby = "Nearby"

    var description: String {
        switch self {
        case .all:
            return "Show all tee times"
        case .nearby:
            return "Filter by location"
        }
    }
}

// MARK: - Location Filter Sheet
struct LocationFilterSheet: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var filterMode: LocationFilterMode
    @Binding var manualZipCode: String
    @Binding var radiusMiles: Int
    @Environment(\.dismiss) var dismiss

    @State private var isRequestingPermission = false

    var body: some View {
        NavigationView {
            Form {
                // Filter Mode Section
                Section {
                    Picker("Filter Mode", selection: $filterMode) {
                        ForEach(LocationFilterMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Filter Mode")
                } footer: {
                    Text(filterMode.description)
                }

                // Location Settings (only show when nearby mode is selected)
                if filterMode == .nearby {
                    // Permission Status
                    Section {
                        HStack {
                            Image(systemName: locationStatusIcon)
                                .foregroundColor(locationStatusColor)
                            Text(locationStatusText)
                                .font(.subheadline)
                            Spacer()
                        }

                        if locationManager.authorizationStatus == .denied ||
                           locationManager.authorizationStatus == .restricted {
                            Button {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "gear")
                                    Text("Open Settings")
                                }
                            }
                        } else if locationManager.authorizationStatus == .notDetermined {
                            Button {
                                Task {
                                    isRequestingPermission = true
                                    do {
                                        try await locationManager.requestPermission()
                                    } catch {
                                        print("Permission request error: \(error.localizedDescription)")
                                    }
                                    isRequestingPermission = false
                                }
                            } label: {
                                HStack {
                                    if isRequestingPermission {
                                        ProgressView()
                                    } else {
                                        Image(systemName: "location.circle")
                                        Text("Request Location Permission")
                                    }
                                }
                            }
                            .disabled(isRequestingPermission)
                        }
                    } header: {
                        Text("Location Permission")
                    } footer: {
                        Text("Golf Dads needs your location to show nearby tee times. You can also manually enter a zip code below.")
                    }

                    // Manual Zip Code Override
                    Section {
                        TextField("Zip Code", text: $manualZipCode)
                            .keyboardType(.numberPad)
                            .textContentType(.postalCode)

                        if !manualZipCode.isEmpty {
                            Button("Clear Zip Code") {
                                manualZipCode = ""
                            }
                            .foregroundColor(.red)
                        }
                    } header: {
                        Text("Manual Location (Optional)")
                    } footer: {
                        Text("Enter a zip code to search around a specific location, such as when traveling. Leave empty to use your device location.")
                    }

                    // Radius Slider
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Search Radius")
                                Spacer()
                                Text("\(radiusMiles) miles")
                                    .foregroundColor(.secondary)
                            }

                            Slider(value: Binding(
                                get: { Double(radiusMiles) },
                                set: { radiusMiles = Int($0) }
                            ), in: 5...100, step: 5)
                        }
                    } footer: {
                        Text("Tee times within this radius will be shown.")
                    }
                }
            }
            .navigationTitle("Location Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Location Status Helpers

    private var locationStatusIcon: String {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return "checkmark.circle.fill"
        case .denied, .restricted:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        @unknown default:
            return "questionmark.circle.fill"
        }
    }

    private var locationStatusColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }

    private var locationStatusText: String {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return "Location access granted"
        case .denied:
            return "Location access denied"
        case .restricted:
            return "Location access restricted"
        case .notDetermined:
            return "Location permission not requested"
        @unknown default:
            return "Unknown status"
        }
    }
}

// MARK: - Preview
#Preview {
    LocationFilterSheet(
        locationManager: LocationManager(),
        filterMode: .constant(.nearby),
        manualZipCode: .constant(""),
        radiusMiles: .constant(25)
    )
}
