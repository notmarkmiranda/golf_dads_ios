# Configuration Files

This directory contains environment-specific configuration files for the Golf Dads iOS app.

## Setup Instructions

### 1. Create Your Configuration Files

Copy the example files and fill in your actual values:

```bash
cd Config/
cp Development.xcconfig.example Development.xcconfig
cp Production.xcconfig.example Production.xcconfig
```

### 2. Fill In Values

Edit `Development.xcconfig`:
```
API_BASE_URL = http:/​/localhost:3000/api
GOOGLE_CLIENT_ID = your-actual-dev-client-id.apps.googleusercontent.com
DEVELOPMENT_BUNDLE_ID = com.golfdads.GolfDads.dev
```

Edit `Production.xcconfig`:
```
API_BASE_URL = https://your-production-api.onrender.com/api
GOOGLE_CLIENT_ID = your-actual-prod-client-id.apps.googleusercontent.com
PRODUCTION_BUNDLE_ID = com.golfdads.GolfDads
```

### 3. Get Google OAuth Client ID

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create one)
3. Go to **APIs & Services → Credentials**
4. Click **Create Credentials → OAuth 2.0 Client ID**
5. Select **iOS** as application type
6. Enter your bundle identifier: `com.golfdads.GolfDads`
7. Copy the generated Client ID

**Note:** You'll need separate Client IDs for Development and Production.

### 4. Configure Xcode Project

1. Open `GolfDads.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the **GolfDads** target
4. Go to **Info** tab
5. Under **Custom iOS Target Properties**, add these keys:

   ```xml
   <key>API_BASE_URL</key>
   <string>$(API_BASE_URL)</string>

   <key>GOOGLE_CLIENT_ID</key>
   <string>$(GOOGLE_CLIENT_ID)</string>
   ```

6. Go to **Build Settings** tab
7. Search for "Based on Configuration File"
8. Set **Debug** to use `Development.xcconfig`
9. Set **Release** to use `Production.xcconfig`

### 5. Add URL Scheme for Google Sign-In

1. In Xcode, select the **GolfDads** target
2. Go to **Info** tab
3. Expand **URL Types**
4. Click **+** to add a new URL type
5. Set **URL Schemes** to your reversed client ID:
   - Format: `com.googleusercontent.apps.YOUR_CLIENT_ID`
   - Example: `com.googleusercontent.apps.123456789-abcdefg.apps.googleusercontent.com`

## Using Configuration in Code

### APIConfiguration Service

Create a service to read these values:

```swift
import Foundation

struct APIConfiguration {
    static let baseURL: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String else {
            fatalError("API_BASE_URL not found in Info.plist")
        }
        return url
    }()

    static let googleClientID: String = {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String else {
            fatalError("GOOGLE_CLIENT_ID not found in Info.plist")
        }
        return clientID
    }()
}
```

### Usage Example

```swift
// In NetworkService
let apiURL = APIConfiguration.baseURL + "/users"

// In Google Sign-In setup
GIDSignIn.sharedInstance.configuration = GIDConfiguration(
    clientID: APIConfiguration.googleClientID
)
```

## Security Notes

⚠️ **IMPORTANT:**
- Never commit `Development.xcconfig` or `Production.xcconfig` to git
- Only commit the `.example` files
- The actual `.xcconfig` files are in `.gitignore`
- Never hardcode API keys or secrets in code
- Use environment variables or config files for all sensitive data

## Environment Detection

You can detect which environment you're running in:

```swift
#if DEBUG
let environment = "Development"
let apiURL = APIConfiguration.baseURL // Points to localhost
#else
let environment = "Production"
let apiURL = APIConfiguration.baseURL // Points to production server
#endif
```

## Troubleshooting

### "API_BASE_URL not found" Error

1. Check that you created `Development.xcconfig` (not just the example)
2. Verify the file is added to Xcode project
3. Check Build Settings → Based on Configuration File is set correctly
4. Clean build folder and rebuild

### Google Sign-In Not Working

1. Verify `GOOGLE_CLIENT_ID` is correct in your `.xcconfig`
2. Check URL Scheme is set correctly (reversed client ID)
3. Ensure you're using the iOS client ID (not web client ID)
4. Check that bundle identifier matches Google Cloud Console

### Different API for Simulator vs Device

You can use different URLs for simulator and device:

```swift
static let baseURL: String = {
    #if targetEnvironment(simulator)
    return "http://localhost:3000/api"  // Simulator
    #else
    guard let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String else {
        fatalError("API_BASE_URL not found")
    }
    return url  // Real device
    #endif
}()
```

## Example Development Setup

**Development.xcconfig (your actual file):**
```
API_BASE_URL = http:/​/localhost:3000/api
GOOGLE_CLIENT_ID = 123456789-abcdefg.apps.googleusercontent.com
DEVELOPMENT_BUNDLE_ID = com.golfdads.GolfDads.dev
```

**When running on simulator:**
- Connects to `http://localhost:3000/api`
- Uses development Google OAuth credentials
- Uses development bundle identifier

**Production.xcconfig (your actual file):**
```
API_BASE_URL = https://golf-dads-api.onrender.com/api
GOOGLE_CLIENT_ID = 987654321-hijklmn.apps.googleusercontent.com
PRODUCTION_BUNDLE_ID = com.golfdads.GolfDads
```

**When building for App Store:**
- Connects to production Render API
- Uses production Google OAuth credentials
- Uses production bundle identifier

## Next Steps

After setup:

1. ✅ Copy example files to actual config files
2. ✅ Fill in your API URL and Google Client ID
3. ✅ Configure Xcode to use these files
4. ✅ Add URL scheme for Google Sign-In
5. ✅ Create `APIConfiguration.swift` service
6. ✅ Test that values are loaded correctly
