# Google Sign-In Setup Guide - iOS App

This guide walks through setting up Google Sign-In authentication for the Golf Dads iOS app.

## Prerequisites

- Google Cloud Console account
- Xcode 16+
- iOS 17+ device or simulator
- Golf Dads API with Google auth endpoint implemented

## Step 1: Google Cloud Console Setup

### 1.1 Create OAuth 2.0 Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Create a new project or select existing project
3. Navigate to **APIs & Services → Credentials**
4. Click **Create Credentials → OAuth 2.0 Client ID**

### 1.2 Create iOS Client ID

1. Select **iOS** as application type
2. Enter **Bundle ID**: `com.golfdads.GolfDads` (or your custom bundle ID)
3. Click **Create**
4. Copy the **Client ID** - you'll need this for configuration

**Format**: `XXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com`

### 1.3 Create Web Client ID (for Backend Verification)

1. Create another OAuth client
2. Select **Web application** as application type
3. Add authorized redirect URIs if needed
4. Copy this **Web Client ID** for your Rails API configuration

## Step 2: iOS App Configuration

### 2.1 Create Configuration Files

The app uses `.xcconfig` files for environment-specific settings:

```bash
cd Config/
cp Development.xcconfig.example Development.xcconfig
cp Production.xcconfig.example Production.xcconfig
```

### 2.2 Update Configuration Files

Edit both files and update with your Google Client IDs:

**Development.xcconfig:**
```
GOOGLE_CLIENT_ID = YOUR_IOS_CLIENT_ID_HERE.apps.googleusercontent.com
```

**Production.xcconfig:**
```
GOOGLE_CLIENT_ID = YOUR_IOS_CLIENT_ID_HERE.apps.googleusercontent.com
```

**Note**: Use the **iOS Client ID** from Step 1.2, not the Web Client ID.

### 2.3 Configure URL Scheme in Xcode

Google Sign-In requires a custom URL scheme for the OAuth callback:

1. Open `GolfDads.xcodeproj` in Xcode
2. Select the **GolfDads** project in the navigator
3. Select the **GolfDads** target
4. Go to the **Info** tab
5. Expand **URL Types**
6. Click **+** to add a new URL Type
7. Set the following:
   - **Identifier**: `com.googleusercontent.apps.YOUR_CLIENT_ID`
   - **URL Schemes**: Your reversed client ID

**Example**:
- If your iOS Client ID is: `714139606616-abc123xyz.apps.googleusercontent.com`
- URL Scheme should be: `com.googleusercontent.apps.714139606616-abc123xyz`

**To get your reversed client ID:**
```
Take: 714139606616-abc123xyz.apps.googleusercontent.com
Use:  com.googleusercontent.apps.714139606616-abc123xyz
```

### 2.4 Verify Info.plist

Your `Info.plist` should automatically pick up the `GOOGLE_CLIENT_ID` from your xcconfig files. Verify it contains:

```xml
<key>GOOGLE_CLIENT_ID</key>
<string>$(GOOGLE_CLIENT_ID)</string>
```

This is already configured in the project.

## Step 3: Code Integration

### 3.1 GoogleAuthService

The `GoogleAuthService` is already implemented at `Services/GoogleAuthService.swift`. It handles:

- Google Sign-In SDK initialization
- OAuth flow presentation
- ID token extraction
- Error handling and mapping

**Usage:**
```swift
let googleAuthService = GoogleAuthService()

do {
    let idToken = try await googleAuthService.signIn()
    // Send idToken to your backend
} catch {
    print("Google Sign-In failed: \(error)")
}
```

### 3.2 AuthenticationService Integration

The `AuthenticationService` already has a `googleSignIn` method:

```swift
func googleSignIn(idToken: String) async throws -> AuthenticationResponse
```

This method:
1. Sends the Google ID token to your backend
2. Receives authentication token from your API
3. Saves the token to Keychain
4. Returns the authenticated user

### 3.3 Update AuthenticationManager

Add Google Sign-In support to `AuthenticationManager.swift`:

```swift
func signInWithGoogle() async throws {
    isLoading = true
    errorMessage = nil

    do {
        // Get Google ID token
        let idToken = try await googleAuthService.signIn()

        // Authenticate with backend
        let response = try await authService.googleSignIn(idToken: idToken)

        // Update state
        await MainActor.run {
            self.authenticatedUser = response.user
            self.isLoading = false
        }
    } catch {
        await MainActor.run {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
        throw error
    }
}
```

### 3.4 Update LoginView UI

Add a Google Sign-In button to `Views/Authentication/LoginView.swift`:

```swift
// After the existing login button, add:

Button(action: {
    Task {
        do {
            try await authManager.signInWithGoogle()
        } catch {
            // Error already handled by AuthenticationManager
        }
    }
}) {
    HStack {
        Image(systemName: "g.circle.fill")
        Text("Sign in with Google")
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(Color.white)
    .foregroundColor(.black)
    .cornerRadius(10)
    .overlay(
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
    )
}
.disabled(authManager.isLoading)

Text("or")
    .foregroundColor(.white.opacity(0.7))
    .padding(.vertical, 8)
```

## Step 4: Backend API Requirements

Your Rails API must implement the Google Sign-In endpoint:

**Endpoint**: `POST /api/v1/auth/google`

**Request Body**:
```json
{
  "idToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6..."
}
```

**Response** (on success):
```json
{
  "token": "your_jwt_token",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

See the Rails API `GOOGLE_SIGNIN_SETUP.md` for implementation details.

## Step 5: Testing

### 5.1 Test Flow

1. Launch app in simulator or device
2. Tap "Sign in with Google" button
3. Google Sign-In sheet should appear
4. Select Google account or sign in
5. Grant permissions
6. App should authenticate and navigate to main screen

### 5.2 Debugging

**Common Issues:**

**Issue**: "Unable to find root view controller"
- **Solution**: Ensure your app has a valid window scene

**Issue**: Google Sign-In sheet doesn't appear
- **Solution**: Check URL scheme is correctly configured in Xcode

**Issue**: "Invalid client ID"
- **Solution**: Verify:
  - Correct iOS Client ID in xcconfig files
  - Bundle ID matches Google Console configuration
  - URL scheme matches reversed client ID

**Issue**: "Failed to get ID token from Google"
- **Solution**: User may have canceled or permissions denied

**Issue**: Backend returns 401/422
- **Solution**: Check Rails API Google auth endpoint implementation

### 5.3 Test with Real Device

Google Sign-In works better on real devices. To test:

1. Connect iPhone via USB
2. Select device in Xcode
3. Build and run (Cmd + R)
4. Test full authentication flow

## Step 6: Security Considerations

1. **Never commit actual xcconfig files**: They contain sensitive IDs
   - `Development.xcconfig` is in `.gitignore`
   - `Production.xcconfig` is in `.gitignore`
   - Only commit `.example` files

2. **Verify tokens on backend**: Always verify Google ID tokens server-side
   - Use Google's token verification library
   - Don't trust client-sent tokens without verification

3. **Use separate credentials**: Use different Google Client IDs for:
   - Development (with dev bundle ID)
   - Production (with production bundle ID)

## Step 7: App Store Submission

Before submitting to App Store:

1. Ensure Production.xcconfig has production Client ID
2. Verify URL scheme is configured for production bundle ID
3. Test Google Sign-In with production build
4. Add Google Sign-In to App Privacy details in App Store Connect

## Troubleshooting

### Check Configuration

Run this in Xcode debugger to verify configuration:

```swift
print("Client ID: \(APIConfiguration.shared.googleClientID)")
```

Should print your full Client ID, not empty string or `$(GOOGLE_CLIENT_ID)`.

### Enable Logging

Add to GoogleAuthService for debugging:

```swift
GIDSignIn.sharedInstance.configuration = config
print("🔧 Google Sign-In configured with client ID: \(clientID)")
```

## Additional Resources

- [Google Sign-In for iOS Documentation](https://developers.google.com/identity/sign-in/ios)
- [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
- [OAuth 2.0 Playground](https://developers.google.com/oauthplayground/)

## Support

For issues specific to:
- **iOS configuration**: Check this guide and Xcode settings
- **Google Cloud Console**: See Google's documentation
- **Backend integration**: See Rails API documentation
- **App functionality**: Check Authentication service logs
