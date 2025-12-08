import Foundation

// MARK: - Golf Course Model
struct GolfCourse: Codable, Identifiable, Hashable {
    let id: Int?
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
    let distanceMiles: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case externalId = "external_id"
        case name
        case clubName = "club_name"
        case address
        case city
        case state
        case zipCode = "zip_code"
        case country
        case latitude
        case longitude
        case phone
        case website
        case distanceMiles = "distance_miles"
    }

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

    enum CodingKeys: String, CodingKey {
        case golfCourses = "golf_courses"
    }
}

struct GolfCourseResponse: Codable {
    let golfCourse: GolfCourse

    enum CodingKeys: String, CodingKey {
        case golfCourse = "golf_course"
    }
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
        return response.golfCourses
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
                let externalId: String
                let name: String
                let clubName: String
                let address: String
                let city: String
                let state: String
                let zipCode: String
                let country: String
                let latitude: Double
                let longitude: Double
                let phone: String
                let website: String
            }
        }

        let endpoint = APIConfiguration.Endpoint.golfCoursesCache
        let body = CacheRequest(
            golfCourse: .init(
                externalId: course.externalId ?? "",
                name: course.name,
                clubName: course.clubName ?? "",
                address: course.address ?? "",
                city: course.city ?? "",
                state: course.state ?? "",
                zipCode: course.zipCode ?? "",
                country: course.country ?? "",
                latitude: course.latitude ?? 0,
                longitude: course.longitude ?? 0,
                phone: course.phone ?? "",
                website: course.website ?? ""
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
