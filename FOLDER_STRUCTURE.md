# Golf Dads iOS - Folder Structure

This document describes the organization of the Golf Dads iOS codebase.

## Project Structure

```
GolfDads/
├── App/
│   └── GolfDadsApp.swift              # App entry point with @main
│
├── Models/
│   ├── User.swift                     # User model (Codable)
│   ├── Group.swift                    # Group model (Codable)
│   ├── TeeTimePosting.swift          # Tee time posting model (Codable)
│   └── Reservation.swift              # Reservation model (Codable)
│
├── Views/
│   ├── Authentication/
│   │   ├── WelcomeView.swift         # Welcome screen with auth options
│   │   ├── SignUpView.swift          # Sign up form
│   │   └── LoginView.swift           # Login form
│   ├── Browse/
│   │   └── BrowseView.swift          # Browse public tee times
│   ├── TeeTimes/
│   │   ├── TeeTimeDetailView.swift   # Tee time detail & reserve
│   │   ├── CreateTeeTimeView.swift   # Create new posting
│   │   └── MyPostingsView.swift      # User's postings
│   ├── Groups/
│   │   ├── GroupsView.swift          # Groups list
│   │   └── GroupDetailView.swift     # Group detail with members
│   ├── Profile/
│   │   ├── ProfileView.swift         # User profile
│   │   └── MyReservationsView.swift  # User's reservations
│   ├── Components/
│   │   └── (Reusable UI components)  # Shared views
│   ├── ContentView.swift              # Temporary main view
│   └── MainTabView.swift              # Main tab navigation (future)
│
├── ViewModels/
│   ├── Authentication/
│   │   ├── WelcomeViewModel.swift
│   │   ├── SignUpViewModel.swift
│   │   └── LoginViewModel.swift
│   ├── Browse/
│   │   └── BrowseViewModel.swift
│   ├── TeeTimes/
│   │   ├── TeeTimeDetailViewModel.swift
│   │   ├── CreateTeeTimeViewModel.swift
│   │   └── MyPostingsViewModel.swift
│   ├── Groups/
│   │   ├── GroupsViewModel.swift
│   │   └── GroupDetailViewModel.swift
│   └── Profile/
│       ├── ProfileViewModel.swift
│       └── MyReservationsViewModel.swift
│
├── Services/
│   ├── APIConfiguration.swift         # API base URL & config
│   ├── NetworkService.swift           # HTTP client with URLSession
│   ├── AuthenticationService.swift    # Auth operations
│   ├── APIClient.swift                # API endpoint methods
│   └── KeychainService.swift          # Secure token storage
│
├── Managers/
│   └── AuthenticationManager.swift    # Global auth state
│
├── Utils/
│   ├── Extensions/
│   │   └── (Swift extensions)         # String, Date, View extensions
│   └── Helpers/
│       └── (Helper functions)         # Utility functions
│
├── PreviewContent/
│   └── MockData.swift                 # Mock data for SwiftUI previews
│
└── Assets.xcassets/                   # Images, colors, icons

GolfDadsTests/
├── ModelTests/                        # Model unit tests
├── ServiceTests/                      # Service unit tests
├── ViewModelTests/                    # ViewModel unit tests
├── ViewTests/                         # View tests (ViewInspector)
└── Mocks/                             # Mock objects for testing

GolfDadsUITests/                       # UI automation tests (optional)
```

## Architecture

**MVVM (Model-View-ViewModel)**
- **Models:** Data structures that match API responses (Codable)
- **Views:** SwiftUI views (UI only, no business logic)
- **ViewModels:** Business logic, state management, API calls
- **Services:** Reusable services (networking, auth, storage)
- **Managers:** Global state managers (auth state)

## File Organization Rules

1. **One model per file** - Each model gets its own Swift file
2. **Views are paired with ViewModels** - Related files in parallel structure
3. **Services are protocol-based** - Each service has a protocol for testability
4. **Tests mirror source structure** - Test files match source file organization
5. **Reusable components** - Shared UI goes in Views/Components/

## Naming Conventions

- **Models:** Singular nouns (User, Group, TeeTimePosting)
- **Views:** Descriptive + "View" suffix (LoginView, BrowseView)
- **ViewModels:** Matching view name + "ViewModel" (LoginViewModel)
- **Services:** Descriptive + "Service" suffix (NetworkService)
- **Protocols:** Same as class name + "Protocol" suffix (NetworkServiceProtocol)
- **Mocks:** "Mock" + protocol name (MockNetworkService)

## Adding New Features

When adding a new feature:

1. Create the **Model** (if needed) in `Models/`
2. Create the **View** in appropriate `Views/` subfolder
3. Create the **ViewModel** in matching `ViewModels/` subfolder
4. Add any new **API methods** to `APIClient.swift`
5. Create **tests** in matching test folder
6. Add **mock data** to `PreviewContent/MockData.swift`

## Testing Organization

- **ModelTests:** Test Codable conformance, validation, computed properties
- **ServiceTests:** Test services with mocked dependencies
- **ViewModelTests:** Test business logic with mocked services
- **ViewTests:** Test view rendering with ViewInspector
- **Mocks:** Reusable mock objects implementing service protocols
