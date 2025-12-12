import Foundation

// MARK: - Favorite Course Service Protocol
protocol FavoriteCourseServiceProtocol {
    func getFavorites() async throws -> [GolfCourse]
    func addFavorite(courseId: Int) async throws -> GolfCourse
    func removeFavorite(courseId: Int) async throws -> GolfCourse
}

// MARK: - Favorite Course Service
class FavoriteCourseService: FavoriteCourseServiceProtocol {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Get Favorites
    func getFavorites() async throws -> [GolfCourse] {
        let endpoint = APIConfiguration.Endpoint.getFavorites
        let response: FavoriteCoursesResponse = try await networkService.request(
            endpoint: endpoint,
            method: .get,
            body: nil as String?,
            requiresAuth: true
        )
        return response.golfCourses
    }

    // MARK: - Add Favorite
    func addFavorite(courseId: Int) async throws -> GolfCourse {
        struct AddFavoriteRequest: Encodable {
            let golfCourseId: Int
        }

        let endpoint = APIConfiguration.Endpoint.addFavorite
        let body = AddFavoriteRequest(golfCourseId: courseId)
        let response: FavoriteCourseResponse = try await networkService.request(
            endpoint: endpoint,
            method: .post,
            body: body,
            requiresAuth: true
        )
        return response.golfCourse
    }

    // MARK: - Remove Favorite
    func removeFavorite(courseId: Int) async throws -> GolfCourse {
        let endpoint = APIConfiguration.Endpoint.removeFavorite(courseId: courseId)
        let response: FavoriteCourseResponse = try await networkService.request(
            endpoint: endpoint,
            method: .delete,
            body: nil as String?,
            requiresAuth: true
        )
        return response.golfCourse
    }
}

// MARK: - Response Types

struct FavoriteCoursesResponse: Decodable {
    let golfCourses: [GolfCourse]
    // Note: convertFromSnakeCase decoder strategy automatically handles golf_courses -> golfCourses
}

struct FavoriteCourseResponse: Decodable {
    let golfCourse: GolfCourse
    let message: String
    // Note: convertFromSnakeCase decoder strategy automatically handles golf_course -> golfCourse
}
