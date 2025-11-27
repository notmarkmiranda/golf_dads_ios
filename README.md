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

**Phase 4 of 6: Authentication UI - Complete!**

### Progress Overview
- ✅ **Phase 1:** Project Setup & Configuration (6/6 steps) - **100% Complete**
- ✅ **Phase 2:** Core Services & Authentication (10/10 steps) - **100% Complete**
- ✅ **Phase 3:** Models & API Client (4/8 steps) - **50% Complete**
- ✅ **Phase 4:** Authentication Flows (4/8 steps) - **50% Complete** ← Current
- 💡 **Phase 5:** Main Features (0/10 steps)
- 💡 **Phase 6:** Polish & App Store (0/3 steps)

**Total Progress: 24/45 steps (53% complete)**

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

**Phase 3: Models - IN PROGRESS**
- ✅ AuthenticatedUser - User model with Codable
- ⏳ TeeTime model
- ⏳ Group model
- ⏳ Reservation model

**Phase 4: Authentication UI - IN PROGRESS**
- ✅ WelcomeView - Golf-themed landing screen with branding
- ✅ LoginView - Email/password authentication with validation
- ✅ SignUpView - User registration with real-time validation
- ✅ RootView - Root navigation managing auth state
- ⏳ Google Sign-In integration
- ⏳ Password reset flow
- ⏳ Email verification
- ⏳ Profile setup

### 🧪 Test Results

**64/64 tests passing** (100%)

- ✅ APIConfigurationTests: 7/7 passing
- ✅ KeychainServiceTests: 16/16 passing
- ✅ NetworkServiceTests: 15/15 passing
- ✅ AuthenticationServiceTests: 11/11 passing
- ✅ AuthenticationManagerTests: 15/15 passing

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

**Main App (Placeholder):**
- Tab bar navigation: Home, Groups, Tee Times, Profile
- User profile display
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
