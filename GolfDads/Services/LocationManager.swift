import Foundation
import CoreLocation
import Combine

// MARK: - Location Errors
enum LocationError: LocalizedError {
    case permissionDenied
    case locationUnavailable
    case timeout
    case invalidZipCode
    case geocodingFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission was denied. Please enable location services in Settings."
        case .locationUnavailable:
            return "Unable to determine your current location. Please try again."
        case .timeout:
            return "Location request timed out. Please try again."
        case .invalidZipCode:
            return "Invalid zip code provided."
        case .geocodingFailed:
            return "Failed to convert zip code to coordinates."
        }
    }
}

// MARK: - Location Manager Protocol
protocol LocationManagerProtocol: ObservableObject {
    var authorizationStatus: CLAuthorizationStatus { get }
    var lastKnownLocation: CLLocationCoordinate2D? { get }
    var isLoading: Bool { get }

    func requestPermission() async throws
    func getCurrentLocation() async throws -> CLLocationCoordinate2D
    func geocodeZipCode(_ zipCode: String) async throws -> CLLocationCoordinate2D
}

// MARK: - Location Manager
@MainActor
class LocationManager: NSObject, LocationManagerProtocol, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastKnownLocation: CLLocationCoordinate2D?
    @Published var isLoading: Bool = false

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    private var authContinuation: CheckedContinuation<Void, Error>?

    // Cache location for 5 minutes to reduce battery drain
    private var cachedLocation: (coordinate: CLLocationCoordinate2D, timestamp: Date)?
    private let locationCacheTimeout: TimeInterval = 300 // 5 minutes

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Permission Request
    func requestPermission() async throws {
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            return // Already authorized
        }

        return try await withCheckedThrowingContinuation { continuation in
            authContinuation = continuation
            locationManager.requestWhenInUseAuthorization()
        }
    }

    // MARK: - Get Current Location
    func getCurrentLocation() async throws -> CLLocationCoordinate2D {
        // Check cache first
        if let cached = cachedLocation,
           Date().timeIntervalSince(cached.timestamp) < locationCacheTimeout {
            return cached.coordinate
        }

        // Check permission
        if authorizationStatus != .authorizedWhenInUse && authorizationStatus != .authorizedAlways {
            throw LocationError.permissionDenied
        }

        isLoading = true
        defer { isLoading = false }

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()

            // Timeout after 10 seconds
            Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                if locationContinuation != nil {
                    locationContinuation = nil
                    continuation.resume(throwing: LocationError.timeout)
                }
            }
        }
    }

    // MARK: - Geocode Zip Code
    func geocodeZipCode(_ zipCode: String) async throws -> CLLocationCoordinate2D {
        // Validate zip code format (5 digits)
        guard zipCode.range(of: "^\\d{5}$", options: .regularExpression) != nil else {
            throw LocationError.invalidZipCode
        }

        isLoading = true
        defer { isLoading = false }

        return try await withCheckedThrowingContinuation { continuation in
            // Add "USA" to help CLGeocoder identify the country
            let addressString = "\(zipCode), USA"

            geocoder.geocodeAddressString(addressString) { placemarks, error in
                if let error = error {
                    print("Geocoding error: \(error.localizedDescription)")
                    continuation.resume(throwing: LocationError.geocodingFailed)
                    return
                }

                guard let coordinate = placemarks?.first?.location?.coordinate else {
                    print("No coordinate found in placemarks")
                    continuation.resume(throwing: LocationError.geocodingFailed)
                    return
                }

                print("✅ Geocoded \(zipCode) to: \(coordinate.latitude), \(coordinate.longitude)")
                continuation.resume(returning: coordinate)
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus

            // Handle authorization continuation
            if let continuation = authContinuation {
                authContinuation = nil
                if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
                    continuation.resume()
                } else if authorizationStatus == .denied || authorizationStatus == .restricted {
                    continuation.resume(throwing: LocationError.permissionDenied)
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }

            let coordinate = location.coordinate
            lastKnownLocation = coordinate

            // Cache the location
            cachedLocation = (coordinate: coordinate, timestamp: Date())

            // Resume continuation if waiting
            if let continuation = locationContinuation {
                locationContinuation = nil
                continuation.resume(returning: coordinate)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("Location error: \(error.localizedDescription)")

            if let continuation = locationContinuation {
                locationContinuation = nil
                continuation.resume(throwing: LocationError.locationUnavailable)
            }
        }
    }
}
