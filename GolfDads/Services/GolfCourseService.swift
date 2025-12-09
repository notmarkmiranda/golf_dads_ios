import Foundation

// MARK: - Golf Course Model
struct GolfCourse: Codable, Identifiable, Hashable {
    let id: Int?
    let externalId: Int?
    let name: String
    let clubName: String?
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let country: String?
    let latitude: Double?
    let longitude: Double?
    let phone: String?
    let website: String?
    let distanceMiles: Double?
    // Note: convertFromSnakeCase decoder strategy automatically handles snake_case -> camelCase

    var displayLocation: String {
        var parts: [String] = []
        if let city = city { parts.append(city) }
        if let state = state { parts.append(state) }
        return parts.joined(separator: ", ")
    }

    var hasCoordinates: Bool {
        return latitude != nil && longitude != nil
    }
}

// MARK: - Golf Course Response
struct GolfCoursesResponse: Codable {
    let golfCourses: [GolfCourse]
    // Note: convertFromSnakeCase decoder strategy automatically handles golf_courses -> golfCourses
}

struct GolfCourseResponse: Codable {
    let golfCourse: GolfCourse
    // Note: convertFromSnakeCase decoder strategy automatically handles golf_course -> golfCourse
}

// MARK: - Golf Course Service Protocol
protocol GolfCourseServiceProtocol {
    func search(query: String) async throws -> [GolfCourse]
    func getNearby(latitude: Double, longitude: Double, radius: Int) async throws -> [GolfCourse]
    func cacheCourse(_ course: GolfCourse) async throws -> GolfCourse
}

// MARK: - Golf Course Service
class GolfCourseService: GolfCourseServiceProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Search Courses
    func search(query: String) async throws -> [GolfCourse] {
        guard !query.isEmpty else {
            return []
        }

        let endpoint = APIConfiguration.Endpoint.golfCoursesSearch(query: query)
        let response: GolfCoursesResponse = try await networkService.request(
            endpoint: endpoint,
            method: .get,
            body: nil as String?,
            requiresAuth: true
        )

        // Deduplicate courses (client-side safety measure)
        var seen = Set<String>()
        return response.golfCourses.filter { course in
            let key: String
            if let externalId = course.externalId {
                key = "ext_\(externalId)"
            } else {
                // Use name + city + state as fallback
                let name = course.name.lowercased().trimmingCharacters(in: .whitespaces)
                let city = course.city?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
                let state = course.state?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
                key = "name_\(name)_\(city)_\(state)"
            }

            if seen.contains(key) {
                return false
            } else {
                seen.insert(key)
                return true
            }
        }
    }

    // MARK: - Get Nearby Courses
    func getNearby(latitude: Double, longitude: Double, radius: Int) async throws -> [GolfCourse] {
        let endpoint = APIConfiguration.Endpoint.golfCoursesNearby(
            latitude: latitude,
            longitude: longitude,
            radius: radius
        )
        let response: GolfCoursesResponse = try await networkService.request(
            endpoint: endpoint,
            method: .get,
            body: nil as String?,
            requiresAuth: true
        )
        return response.golfCourses
    }

    // MARK: - Cache Course
    func cacheCourse(_ course: GolfCourse) async throws -> GolfCourse {
        struct CacheRequest: Encodable {
            let golfCourse: GolfCourseData

            struct GolfCourseData: Encodable {
                let externalId: String?
                let name: String
                let clubName: String?
                let address: String?
                let city: String?
                let state: String?
                let zipCode: String?
                let country: String?
                let latitude: Double?
                let longitude: Double?
                let phone: String?
                let website: String?
            }
        }

        let endpoint = APIConfiguration.Endpoint.golfCoursesCache
        let externalIdString = course.externalId.map { String($0) }
        let body = CacheRequest(
            golfCourse: .init(
                externalId: externalIdString,
                name: course.name,
                clubName: course.clubName,
                address: course.address,
                city: course.city,
                state: course.state,
                zipCode: course.zipCode,
                country: course.country,
                latitude: course.latitude,
                longitude: course.longitude,
                phone: course.phone,
                website: course.website
            )
        )

        let response: GolfCourseResponse = try await networkService.request(
            endpoint: endpoint,
            method: .post,
            body: body,
            requiresAuth: true
        )
        return response.golfCourse
    }
}
