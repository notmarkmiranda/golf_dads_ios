import SwiftUI

struct FavoriteCoursesView: View {

    @State private var favorites: [GolfCourse] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedCourse: GolfCourse?
    @State private var showErrorAlert = false

    private let favoriteService: FavoriteCourseServiceProtocol

    init(favoriteService: FavoriteCourseServiceProtocol = FavoriteCourseService()) {
        self.favoriteService = favoriteService
    }

    var body: some View {
        contentView
            .navigationTitle("Favorite Courses")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadFavorites()
            }
            .sheet(item: $selectedCourse) { course in
                CreateTeeTimeView(preselectedCourse: course)
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {
                    errorMessage = nil
                    showErrorAlert = false
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .task {
                await loadFavorites()
            }
    }

    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            VStack {
                ProgressView("Loading favorites...")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = errorMessage {
            ContentUnavailableView {
                Label("Error", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("Try Again") {
                    Task { await loadFavorites() }
                }
            }
        } else if favorites.isEmpty {
            ContentUnavailableView {
                Label("No Favorite Courses", systemImage: "star")
            } description: {
                Text("Star courses while searching to add them to your favorites")
            }
        } else {
            favoritesList
        }
    }

    private var favoritesList: some View {
        GeometryReader { geometry in
            List {
                ForEach(favorites, id: \.id) { course in
                    FavoriteCourseRow(
                        course: course,
                        onCreateTeeTime: {
                            selectedCourse = course
                        },
                        onRemove: {
                            Task {
                                await removeFavorite(course)
                            }
                        }
                    )
                }
            }
            .listStyle(.insetGrouped)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
    }

    private func loadFavorites() async {
        isLoading = true
        errorMessage = nil

        do {
            favorites = try await favoriteService.getFavorites()
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.userMessage
            } else {
                errorMessage = error.localizedDescription
            }
            showErrorAlert = true
        }

        isLoading = false
    }

    private func removeFavorite(_ course: GolfCourse) async {
        guard let courseId = course.id else { return }

        do {
            _ = try await favoriteService.removeFavorite(courseId: courseId)
            favorites.removeAll { $0.id == courseId }
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.userMessage
            } else {
                errorMessage = "Failed to remove favorite"
            }
            showErrorAlert = true
        }
    }
}

// MARK: - Favorite Course Row

struct FavoriteCourseRow: View {
    let course: GolfCourse
    let onCreateTeeTime: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Course Info
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.headline)

                if !course.displayLocation.isEmpty {
                    Text(course.displayLocation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let clubName = course.clubName {
                    Text(clubName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 16) {
                // Create Tee Time Button
                Button {
                    onCreateTeeTime()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                        .imageScale(.large)
                }
                .buttonStyle(.plain)

                // Remove Favorite Button
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .imageScale(.medium)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FavoriteCoursesView()
}
