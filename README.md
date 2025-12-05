# Golf Dads iOS App

A native iOS application built with SwiftUI that connects to the Golf Dads API. Share available tee time spots with your golf groups and the wider community.

## 📱 Project Overview

This iOS app allows golfers to:
- 🔍 Browse available tee times posted by the community
- ⛳ Create and manage tee time postings
- 👥 Create and join golf groups
- 📋 Reserve spots on posted tee times
- 🔐 Authenticate with email/password or Google Sign-In

## 🏗️ Tech Stack

### Core Framework
- **SwiftUI** - Modern declarative UI framework
- **iOS 17+** - Target minimum version
- **Swift 6** - Latest Swift language features
- **Xcode 16+** - Development environment

### Architecture
- **MVVM** (Model-View-ViewModel) - Clean separation of concerns
- **Async/Await** - Modern concurrency for API calls
- **Combine** - Reactive state management
- **Protocol-oriented** - Dependency injection for testability

### Key Dependencies
- **GoogleSignIn** (8.0.0) - OAuth authentication
- **KeychainAccess** (4.2.2) - Secure token storage
- **ViewInspector** (0.10.3) - SwiftUI testing (tests only)

### Testing
- **XCTest** - Unit testing framework
- **TDD approach** - Write tests first
- **Target: 80%+ test coverage**

## 📊 Project Status

**Phase 5 of 6: Main Features - In Progress!**

### Progress Overview
- ✅ **Phase 1:** Project Setup & Configuration (6/6 steps) - **100% Complete**
- ✅ **Phase 2:** Core Services & Authentication (10/10 steps) - **100% Complete**
- ✅ **Phase 3:** Models & API Client (6/8 steps) - **75% Complete**
- ✅ **Phase 4:** Authentication Flows (4/8 steps) - **50% Complete**
- 🚧 **Phase 5:** Main Features (1/10 steps) - **10% Complete** ← Current
- 💡 **Phase 6:** Polish & App Store (0/3 steps)

**Total Progress: 27/45 steps (60% complete)**

### ✅ Completed Features

**Phase 1: Project Setup**
- Xcode project with SwiftUI
- Git repository with comprehensive .gitignore
- SwiftLint configuration
- MVVM folder structure
- Swift Package Manager dependencies installed
- Environment configuration system

**Phase 2: Core Services - COMPLETE**
- ✅ APIConfiguration - Environment-aware API settings
- ✅ APIError - Comprehensive error handling
- ✅ KeychainService - Secure token storage
- ✅ NetworkService - HTTP client with URLSession
- ✅ AuthenticationService - API authentication endpoints
- ✅ AuthenticationManager - @Observable state management for SwiftUI
- ✅ GroupInvitationService - Service for managing group invitations (send, accept, reject)

**Phase 3: Models - MOSTLY COMPLETE**
- ✅ AuthenticatedUser - User model with Codable
- ✅ TeeTimePosting - Tee time posting model with computed properties
- ✅ Group - Golf group model
- ✅ GroupInvitation - Group invitation model with status enum (pending/accepted/rejected)
- ✅ Reservation - Reservation model
- ✅ Automatic snake_case ↔ camelCase conversion
- ✅ ISO8601 date encoding/decoding

**Phase 4: Authentication UI - COMPLETE**
- ✅ WelcomeView - Golf-themed landing screen with branding
- ✅ LoginView - Email/password authentication with validation
- ✅ SignUpView - User registration with real-time validation
- ✅ RootView - Root navigation managing auth state
- ✅ MainTabView - Tab-based navigation for main app

**Phase 5: Main Features - IN PROGRESS**
- ✅ TeeTimeService - Complete service for tee time CRUD operations
- ✅ ReservationService - Complete service for reservation management
- ✅ BrowseView - Browse and discover public tee time postings
  - Loading, error, and empty states
  - Pull-to-refresh functionality
  - Course info, date/time, available spots
  - Public/private and past indicators
  - Navigation to detail view
- ✅ TeeTimeDetailView - Complete reservation management
  - Detailed information display
  - **Create reservations** - Reserve 1-4 spots on available tee times
  - **Update reservations** - Change number of spots reserved
  - **Cancel reservations** - Remove your reservation with confirmation
  - **Smart validation**: accounts for your current reservation when updating
    - Example: With 2 spots reserved and 2 available, you can update to 4 total
    - Prevents unnecessary validation errors
  - Shows your existing reservation with update/cancel options
  - Reservation details for posting owners (email, spots reserved, time)
  - **Privacy-preserved**: non-owners can see and manage only their own reservation
  - Context-aware success messages for each action:
    - "You've successfully reserved X spot(s) for this tee time."
    - "Your reservation has been updated to X spot(s)."
    - "Your reservation has been cancelled."
  - Idempotent operations (404 on cancel treated as success)
  - Loading states and error handling
- ✅ CreateTeeTimeView - Simplified tee time creation
  - Course name and tee time selection
  - Total spots picker (1-4)
  - Optional "Reserve for myself" (0-3 spots)
  - Available spots calculated automatically
  - Public/private visibility toggle with group selection
  - Optional notes field
  - Form validation and error handling
  - Success confirmation with auto-dismiss
- ✅ MyTeeTimesView - Manage user's tee time postings
  - Display all user's postings
  - Loading, error, and empty states
  - Pull-to-refresh functionality
  - Swipe-to-delete with confirmation
  - Navigation to detail view
  - Create button in toolbar
  - Auto-refresh after creating new posting
- ✅ Group Invitations - Complete invitation management system
  - InvitationsView - View and manage pending invitations
  - SendInvitationView - Send invitations by email
  - Accept/Reject invitation buttons with loading states
  - Success confirmations and error handling
  - GroupDetailView integration with "Invite Members" button
  - Loading, error, and empty states
  - Pull-to-refresh functionality
- ⏳ Groups features (additional features)
- ⏳ Profile management
- ⏳ Google Sign-In integration
- ⏳ Password reset flow
- ⏳ Email verification
- ⏳ Profile setup

### 🧪 Test Results

**114/114 tests passing** (100%)

- ✅ APIConfigurationTests: 7/7 passing
- ✅ KeychainServiceTests: 16/16 passing
- ✅ NetworkServiceTests: 15/15 passing
- ✅ AuthenticationServiceTests: 11/11 passing
- ✅ AuthenticationManagerTests: 15/15 passing
- ✅ GroupTests: 8/8 passing
- ✅ GroupInvitationTests: 10/10 passing
- ✅ GroupInvitationServiceTests: 12/12 passing
- ✅ TeeTimePostingTests: 12/12 passing (includes reservation decoding tests)
- ✅ ReservationTests: 7/7 passing

### 🎨 Current UI Features

**Authentication Flow:**
- Beautiful golf-themed green gradient design
- Welcome screen with "Log In" and "Sign Up" options
- Full login form with email/password validation
- Registration form with real-time validation and visual feedback
- Loading states with progress indicators
- Error message display from API
- Auto-dismiss on successful authentication
- Secure token storage in Keychain
- Persistent login sessions

**Main App Features:**
- Tab bar navigation: My Tee Times, Groups, Browse, Profile
- **My Tee Times** - Create and manage your tee time postings
  - View all your posted tee times
  - Create new tee time postings with form
  - Swipe-to-delete with confirmation
  - Pull-to-refresh functionality
  - Loading, error, and empty states
  - Auto-refresh after creating
- **Create Tee Time** - Simplified posting flow
  - Course name input with auto-capitalization
  - Date/time picker for tee time
  - Total spots picker (1-4)
  - Optional "Reserve for myself" (0-3 spots)
  - Available spots calculated automatically: `total_spots - reservations`
  - Public/private visibility toggle with group selection
  - Optional notes field (multiline)
  - Form validation
  - Success confirmation with auto-dismiss
- **Browse Tee Times** - Discover and view public tee time postings
  - Real-time data from production API
  - Pull-to-refresh functionality
  - Loading, error, and empty states
  - Course name, date/time, available spots
  - Public/private and past indicators
  - Tap to view details
- **Tee Time Details & Reservations** - Complete reservation management
  - Full tee time information display
  - Visual indicators for status (public/private, past)
  - **Make Reservations:**
    - Spot picker with segmented control (1-4 spots)
    - Reserve button with loading states
    - Success confirmation: "You've successfully reserved X spot(s) for this tee time."
  - **Manage Your Reservations:**
    - View your current reservation with spot count
    - Update spot count with smart validation (accounts for your current spots)
    - Cancel reservation with destructive button and confirmation
    - Update success: "Your reservation has been updated to X spot(s)."
    - Cancel success: "Your reservation has been cancelled."
  - **For Posting Owners:**
    - View all reservations (email, spots, time)
    - See who has reserved spots on your postings
  - **Privacy Features:**
    - Non-owners can see and manage only their own reservation
    - Cannot see other users' reservations
  - **Smart Validation:**
    - Update validation accounts for your current reservation
    - Example: 2 spots reserved + 2 available = can update to 4 total
    - Prevents "exceeds available spots" errors on valid updates
  - Idempotent operations (graceful handling of stale data)
  - Smart handling of edge cases (past tee times, fully booked, already cancelled)
  - Tested and working with production API ✅
- User profile display with name and email
- Logout functionality

## 🚀 Getting Started

### Prerequisites

- **macOS** with Xcode 16+ installed
- **iOS 17+** device or simulator
- **Golf Dads API** running (see [golf_dads_api](https://github.com/notmarkmiranda/golf_dads_api))

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/notmarkmiranda/golf_dads_ios.git
   cd golf_dads_ios
   ```

2. **Open in Xcode:**
   ```bash
   open GolfDads.xcodeproj
   ```

3. **Configure environment:**
   ```bash
   cd Config/
   cp Development.xcconfig.example Development.xcconfig
   cp Production.xcconfig.example Production.xcconfig
   ```

4. **Edit your config files** with actual values:
   - API_BASE_URL (your API endpoint)
   - GOOGLE_CLIENT_ID (from Google Cloud Console)

5. **Install dependencies** (if not automatic):
   - In Xcode: **File → Packages → Resolve Package Versions**

6. **Build and run:**
   - Select a simulator or device
   - Press **Cmd + R** to run
   - Press **Cmd + U** to run tests

### Configuration

See [`Config/README.md`](Config/README.md) for detailed configuration instructions.

## 📁 Project Structure

```
GolfDads/
├── App/                        # App entry point
├── Models/                     # Data models (Codable)
├── Views/                      # SwiftUI views
│   ├── Authentication/
│   ├── Browse/
│   ├── TeeTimes/
│   ├── Groups/
│   ├── Profile/
│   └── Components/
├── ViewModels/                 # Business logic
├── Services/                   # Networking, auth, storage
│   ├── APIConfiguration.swift  ✅
│   ├── KeychainService.swift   ✅
│   ├── NetworkService.swift    ⏳
│   └── AuthenticationService.swift ⏳
├── Managers/                   # Global state managers
├── Utils/                      # Extensions, helpers, errors
│   └── APIError.swift          ✅
└── PreviewContent/             # Mock data for previews

GolfDadsTests/
├── ModelTests/
├── ServiceTests/               # Service unit tests
│   ├── APIConfigurationTests.swift ✅
│   └── KeychainServiceTests.swift  ✅
├── ViewModelTests/
└── ViewTests/
```

See [`FOLDER_STRUCTURE.md`](FOLDER_STRUCTURE.md) for complete details.

## 🔧 Development

### Running Tests

```bash
# Run all tests
xcodebuild test -project GolfDads.xcodeproj -scheme GolfDads -destination 'platform=iOS Simulator,name=iPhone 17'

# Or in Xcode: Cmd + U
```

### Code Style

SwiftLint is configured to enforce consistent code style:

```bash
# In Xcode, SwiftLint runs automatically on build
# Or run manually:
swiftlint
```

### Testing Strategy

- **Unit tests** for all services and ViewModels
- **Protocol-based mocking** for dependencies
- **ViewInspector** for SwiftUI view testing
- **TDD approach** - write tests first
- **Target:** 80%+ code coverage

## 📖 Documentation

- [`FOLDER_STRUCTURE.md`](FOLDER_STRUCTURE.md) - Project organization
- [`DEPENDENCIES.md`](DEPENDENCIES.md) - Swift Package Manager guide
- [`Config/README.md`](Config/README.md) - Environment configuration
- [Execution Plan](https://github.com/notmarkmiranda/golf_dads_api/blob/main/mobile_execution_plan.md) - Development roadmap

## 🔗 Related Repositories

- **API Backend:** [golf_dads_api](https://github.com/notmarkmiranda/golf_dads_api)

## 🤝 Contributing

This is a personal project, but suggestions and feedback are welcome!

## 📄 License

This project is private and not licensed for public use.

---

**Built with ❤️ using SwiftUI**
