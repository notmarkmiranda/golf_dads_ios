# Golf Dads iOS - Dependencies

This document lists all external dependencies and how to install them.

## Swift Package Manager (SPM)

All dependencies are managed through Swift Package Manager, which is built into Xcode.

## Required Dependencies

### 1. Google Sign-In for iOS

**Purpose:** OAuth authentication with Google
**Repository:** https://github.com/google/GoogleSignIn-iOS
**Version:** 8.0.0 or later

**Installation:**
1. In Xcode, go to **File → Add Package Dependencies...**
2. Paste the repository URL: `https://github.com/google/GoogleSignIn-iOS`
3. Select version: **8.0.0** (Up to Next Major)
4. Click **Add Package**
5. Select **GoogleSignIn** and **GoogleSignInSwift** targets
6. Click **Add Package**

**Usage:**
```swift
import GoogleSignIn
import GoogleSignInSwift
```

---

### 2. KeychainAccess

**Purpose:** Secure storage for JWT tokens
**Repository:** https://github.com/kishikawakatsumi/KeychainAccess
**Version:** 4.2.2 or later

**Installation:**
1. In Xcode, go to **File → Add Package Dependencies...**
2. Paste the repository URL: `https://github.com/kishikawakatsumi/KeychainAccess`
3. Select version: **4.2.2** (Up to Next Major)
4. Click **Add Package**
5. Select **KeychainAccess** target
6. Click **Add Package**

**Usage:**
```swift
import KeychainAccess
```

---

### 3. ViewInspector

**Purpose:** Testing SwiftUI views
**Repository:** https://github.com/nalexn/ViewInspector
**Version:** 0.10.0 or later

**Installation:**
1. In Xcode, go to **File → Add Package Dependencies...**
2. Paste the repository URL: `https://github.com/nalexn/ViewInspector`
3. Select version: **0.10.0** (Up to Next Major)
4. Click **Add Package**
5. **IMPORTANT:** Only add to **GolfDadsTests** target (not main app)
6. Click **Add Package**

**Usage (in tests only):**
```swift
import ViewInspector
@testable import GolfDads
```

---

## Optional Dependencies (Future Enhancements)

### swift-snapshot-testing

**Purpose:** UI snapshot testing for regression detection
**Repository:** https://github.com/pointfreeco/swift-snapshot-testing
**Version:** 1.17.0 or later

**Installation (when needed):**
1. In Xcode, go to **File → Add Package Dependencies...**
2. Paste the repository URL: `https://github.com/pointfreeco/swift-snapshot-testing`
3. Select version: **1.17.0** (Up to Next Major)
4. Click **Add Package**
5. Only add to **GolfDadsTests** target
6. Click **Add Package**

---

## Installation Order

Follow this order to avoid dependency conflicts:

1. ✅ **KeychainAccess** (no dependencies)
2. ✅ **GoogleSignIn** (has its own dependencies)
3. ✅ **ViewInspector** (test-only)
4. ⏳ **swift-snapshot-testing** (future, test-only)

---

## Verifying Installation

After adding packages, verify they're installed correctly:

1. Go to **File → Packages → Resolve Package Versions**
2. Check **Project Navigator → Package Dependencies**
3. You should see all three packages listed
4. Build the project (**Cmd + B**) to ensure no errors

---

## Troubleshooting

### Package Resolution Fails

1. **File → Packages → Reset Package Caches**
2. **File → Packages → Update to Latest Package Versions**
3. Restart Xcode

### Build Errors After Adding Package

1. Clean build folder: **Product → Clean Build Folder** (Cmd + Shift + K)
2. Delete **DerivedData**: `~/Library/Developer/Xcode/DerivedData`
3. Rebuild: **Product → Build** (Cmd + B)

### Can't Find Package Repository

1. Check your internet connection
2. Verify the repository URL is correct
3. Try accessing the GitHub URL in your browser
4. Check if GitHub is experiencing issues

---

## Using Dependencies in Code

### KeychainService Example

```swift
import KeychainAccess

class KeychainService {
    private let keychain = Keychain(service: "com.golfdads.GolfDads")

    func saveToken(_ token: String) throws {
        try keychain.set(token, key: "jwt_token")
    }

    func getToken() -> String? {
        try? keychain.get("jwt_token")
    }

    func deleteToken() throws {
        try keychain.remove("jwt_token")
    }
}
```

### Google Sign-In Example

```swift
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    var body: some View {
        GoogleSignInButton {
            handleGoogleSignIn()
        }
    }

    func handleGoogleSignIn() {
        GIDSignIn.sharedInstance.signIn(
            withPresenting: getRootViewController()
        ) { result, error in
            // Handle sign-in
        }
    }
}
```

### ViewInspector Example (Tests)

```swift
import XCTest
import ViewInspector
@testable import GolfDads

final class LoginViewTests: XCTestCase {
    func testButtonExists() throws {
        let view = LoginView()
        let button = try view.inspect().find(button: "Log In")
        XCTAssertNotNil(button)
    }
}
```

---

## Package Versions

Current versions as of this setup:

| Package | Minimum Version | Notes |
|---------|----------------|-------|
| GoogleSignIn | 8.0.0 | Latest stable, supports iOS 15+ |
| KeychainAccess | 4.2.2 | Stable, well-maintained |
| ViewInspector | 0.10.0 | SwiftUI testing support |

---

## Notes

- All packages are compatible with iOS 17+ (our target)
- No CocoaPods or Carthage needed - SPM only
- Test-only packages won't increase app size
- Packages are versioned in `Package.resolved` (committed to git)

---

## Next Steps

After installing dependencies:

1. ✅ Add all three required packages via SPM
2. ✅ Verify they appear in Package Dependencies
3. ✅ Build project to ensure no errors
4. ✅ Create `KeychainService.swift` to wrap KeychainAccess
5. ✅ Configure Google Sign-In client ID in project
