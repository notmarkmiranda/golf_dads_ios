# Golf Dads iOS App

A native iOS application built with SwiftUI that connects to the Golf Dads API. Share available tee time spots with your golf groups.

## 📱 Project Overview

This iOS app allows golfers to:
- 🔍 Browse available tee times from your golf groups
- ⛳ Create and manage group tee time postings
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

**App Complete - In Production on TestFlight!**

### Progress Overview
- ✅ **Phase 1:** Project Setup & Configuration - **100% Complete**
- ✅ **Phase 2:** Core Services & Authentication - **100% Complete**
- ✅ **Phase 3:** Models & API Client - **100% Complete**
- ✅ **Phase 4:** Authentication Flows - **100% Complete**
- ✅ **Phase 5:** Main Features - **100% Complete**
- ✅ **Phase 6:** Polish & App Store - **In Production**

**All core features implemented and tested. Currently in active TestFlight distribution.**

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

**Phase 5: Main Features - COMPLETE**
- ✅ TeeTimeService - Complete service for tee time CRUD operations
- ✅ ReservationService - Complete service for reservation management
- ✅ BrowseView - Browse and discover tee times from your groups
  - Shows tee times from groups you're a member of
  - Filters out tee times you own or have reserved
  - Loading, error, and empty states
  - Pull-to-refresh functionality
  - Course info, date/time, available spots
  - Past indicators
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
- ✅ CreateTeeTimeView - Comprehensive tee time creation
  - Golf course search with autocomplete
  - Manual course entry fallback
  - Course name and tee time selection
  - Total spots picker (1-4)
  - Optional "Reserve for myself" (0-3 spots)
  - Available spots calculated automatically
  - Group selection (required - all tee times must be associated with groups)
  - Alert when user has no groups, directing them to create/join groups
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
- ✅ Groups - Complete group management system
  - GroupsView - Browse and manage all your groups
  - CreateGroupView - Create new golf groups
  - GroupDetailView - View group details, members, and tee times
  - EditGroupView - Edit group name and description
  - TransferOwnershipView - Transfer group ownership to another member
  - JoinWithCodeView - Join groups using invite codes with preview
  - Group-specific tee time postings
  - Member management (view, remove members)
  - Owner-only privileges (edit, delete, transfer ownership, remove members)
  - Regenerate invite codes
  - Leave group functionality
- ✅ Favorite Courses
  - FavoriteCoursesView - Manage favorite golf courses
  - Add/remove favorites
  - Quick access from tee time creation
- ✅ Profile Management
  - EditProfileView - Update profile information
    - Name, email, Venmo handle
    - Handicap tracking
    - Home location (zip code)
    - Preferred search radius
  - NotificationSettingsView - Granular push notification preferences
    - Reservation notifications (created/cancelled)
    - Group activity alerts
    - Tee time reminders (24h and 2h before)
    - Per-group notification settings
- ✅ Push Notifications
  - Firebase Cloud Messaging integration
  - Device token registration
  - Notification tap handling with deep linking
  - Background notification support
  - Granular notification preferences
- ✅ Google Sign-In integration
  - OAuth authentication flow
  - Automatic account creation
  - Profile picture sync

### 🧪 Test Results

**105/105 tests passing** (100%)

- ✅ APIConfigurationTests: All passing
- ✅ KeychainServiceTests: All passing
- ✅ NetworkServiceTests: All passing
- ✅ AuthenticationServiceTests: All passing (2 flaky tests disabled with documentation)
- ✅ AuthenticationManagerTests: All passing
- ✅ GoogleAuthServiceTests: All passing (1 flaky test disabled with documentation)
- ✅ GroupTests: All passing
- ✅ TeeTimePostingTests: All passing
- ✅ ReservationTests: All passing

**Note:** A few intermittently flaky tests have been disabled with clear documentation explaining the test environment behavior. All production functionality has been manually verified.

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
- Tab bar navigation: My Tee Times, Groups, Available, Profile
- Smart default tab: Shows Groups if you have no groups, My Tee Times otherwise
- **My Tee Times** - Create and manage your tee time postings
  - View all your posted tee times
  - Create new tee time postings with form
  - Swipe-to-delete with confirmation
  - Pull-to-refresh functionality
  - Loading, error, and empty states
  - Auto-refresh after creating
- **Create Tee Time** - Comprehensive posting flow
  - Golf course search with autocomplete from API
  - Manual course entry fallback
  - Date/time picker for tee time
  - Total spots picker (1-4)
  - Optional "Reserve for myself" (0-3 spots)
  - Available spots calculated automatically: `total_spots - reservations`
  - Group selection required - all tee times must be associated with groups
  - Shows alert if user has no groups, directing them to create/join groups
  - Optional notes field (multiline)
  - Form validation
  - Success confirmation with auto-dismiss
- **Available Tee Times** - Discover tee times from your groups
  - Shows tee times from all groups you're a member of
  - Filters out tee times you own or have already reserved
  - Real-time data from production API
  - Pull-to-refresh functionality
  - Loading, error, and empty states
  - Course name, date/time, available spots
  - Past indicators
  - Tap to view details and reserve spots
- **Tee Time Details & Reservations** - Complete reservation management
  - Full tee time information display
  - Visual indicators for status (past tee times)
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
- **Groups** - Complete group management
  - View all your groups
  - Create new golf groups
  - Join groups via invite code with preview
  - Group details: members, tee times, settings
  - Edit group name and description (owner only)
  - Transfer ownership to another member (owner only)
  - Remove members (owner only)
  - Regenerate invite codes (owner only)
  - Leave group functionality
  - Share group invite codes
  - Deep linking support for invite codes
- **Favorite Courses**
  - Manage favorite golf courses
  - Add/remove favorites
  - Quick access from tee time creation
- **Profile Management**
  - View and edit profile information
  - Update name, email, Venmo handle
  - Set handicap
  - Configure home location (zip code)
  - Set preferred search radius
  - Notification preferences with granular controls
  - Google Sign-In integration
  - Logout functionality
- **Push Notifications**
  - Reservation alerts (created/cancelled)
  - Group activity notifications
  - Tee time reminders (24h and 2h before)
  - Notification tap handling with deep linking
  - Per-group notification settings
  - System settings integration

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

See [`docs/CONFIG_README.md`](docs/CONFIG_README.md) for detailed configuration instructions.

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

## 📦 Releases

### Version 1.2.2 Build 5 (Current - January 2026)
**Latest Updates:**
- 🔒 **Security Enhancement:** Removed public tee times to prevent spam - all tee times now require group membership
- 👥 **Group-First Experience:** App now defaults to Groups tab if user has no groups
- 📱 **Smart Navigation:** Available tab now shows tee times from your groups that you can join
- ⚠️ **User Guidance:** Alert shown when trying to create tee time without groups, directing users to create/join groups first
- ✅ All tests passing (89/89)

**What Changed:**
- Before: Anyone could create public tee times visible to all users ❌
- After: All tee times must be associated with at least one group ✅
- Better spam prevention and more focused group experience
- Available tab filters out your own postings and existing reservations

**Technical Details:**
- Removed `isPublic` state and public/private toggle from CreateTeeTimeView
- BrowseView repurposed to show group tee times with client-side filtering
- MainTabView now conditionally sets default tab based on group membership
- MyTeeTimesView shows alert when user tries to create without groups
- See [GROUP_PREVIEW_IMPLEMENTATION_PLAN.md](../docs/GROUP_PREVIEW_IMPLEMENTATION_PLAN.md) for implementation details

### Version 1.2.1 Build 4 (December 2025)
**Latest Updates:**
- 🐛 **Critical Fix:** Push notifications now display tee times in your local timezone instead of UTC
- 🌍 **Automatic timezone detection:** App sends device timezone during registration
- 🔄 **Smart updates:** Timezone automatically updates when you travel
- ✅ All tests passing (104/104)
- 📖 Comprehensive documentation added

**What This Fixes:**
- Before: Mountain Time user saw "5:15pm" (UTC time) ❌
- After: Mountain Time user sees "10:15am" (correct local time) ✅
- Each user's device shows times in their own timezone automatically

**Technical Details:**
- iOS sends `TimeZone.current.identifier` during device token registration
- Backend formats notification times per-device based on stored timezone
- Backward compatible: older app versions continue working (show UTC with "UTC" suffix)
- See [PUSH_NOTIFICATION_TIMEZONE_FIX.md](../docs/PUSH_NOTIFICATION_TIMEZONE_FIX.md) for full implementation details

### Version 1.2 Build 3 (December 2025)
**Updates:**
- 🐛 **Critical Fix:** Push notifications now work correctly when someone reserves a spot on your tee time
- ✅ All tests passing (105/105)
- 🔧 Enhanced notification tap handling

**Major Features:**
- 🔔 Push notifications with Firebase Cloud Messaging
  - Reservation alerts (created/cancelled)
  - Group activity notifications
  - Tee time reminders (24h and 2h before)
  - Granular notification settings
- 📍 Location preferences and distance filtering
- ⭐ Favorite golf courses
- 👥 Enhanced group owner privileges
- 🐛 iOS 17+ calendar fixes and stability improvements

### Version 1.1 (December 12, 2025)
- Initial TestFlight release
- Core tee time browsing and management
- Group creation and invitations
- Calendar integration
- Profile management

## 📖 Documentation

- [`docs/FOLDER_STRUCTURE.md`](docs/FOLDER_STRUCTURE.md) - Project organization
- [`docs/DEPENDENCIES.md`](docs/DEPENDENCIES.md) - Swift Package Manager guide
- [`docs/CONFIG_README.md`](docs/CONFIG_README.md) - Environment configuration
- [Execution Plan](https://github.com/notmarkmiranda/golf_dads_api/blob/main/mobile_execution_plan.md) - Development roadmap

## 🔗 Related Repositories

- **API Backend:** [golf_dads_api](https://github.com/notmarkmiranda/golf_dads_api)

## 🤝 Contributing

This is a personal project, but suggestions and feedback are welcome!

## 📄 License

This project is private and not licensed for public use.

---

**Built with ❤️ using SwiftUI**
