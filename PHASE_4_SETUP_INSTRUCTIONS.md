# Phase 4: iOS Firebase Integration Setup Instructions

**Follow these steps to integrate Firebase into the iOS app.**

---

## Step 1: Add Firebase SDK via Swift Package Manager

1. Open `GolfDads.xcodeproj` in Xcode
2. Select the project in the navigator (top-level "GolfDads")
3. Select the "GolfDads" target
4. Go to **"Package Dependencies"** tab
5. Click the **"+"** button
6. Enter the Firebase iOS SDK URL:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
7. Click **"Add Package"**
8. In the package selection screen, select **only**:
   - ☑️ **FirebaseMessaging** (for push notifications)
9. Click **"Add Package"**

**Verify:** You should see `firebase-ios-sdk` listed under Package Dependencies.

---

## Step 2: Verify GoogleService-Info.plist

✅ **Already done!** The file exists at:
```
/Users/weatherby/Development/golf_dads/GolfDads/GoogleService-Info.plist
```

**Verify it's added to Xcode:**
1. In Xcode Project Navigator, check if `GoogleService-Info.plist` appears
2. If not visible, drag the file from Finder into the Xcode project
3. Make sure **"Copy items if needed"** is checked
4. Make sure **"GolfDads" target** is selected

---

## Step 3: Update Info.plist

Add notification permission description:

1. Open `Info.plist` in Xcode (or find it at `GolfDads/Info.plist`)
2. Right-click in the editor → **"Add Row"**
3. Add the following key-value pair:
   - **Key:** `NSUserNotificationsUsageDescription`
   - **Type:** String
   - **Value:** `Three Putt sends you notifications about tee time reservations, group activity, and upcoming tee times.`

4. Add Firebase configuration (optional but recommended):
   - **Key:** `FirebaseAppDelegateProxyEnabled`
   - **Type:** Boolean
   - **Value:** `NO` (unchecked)

**Save the file.**

---

## Step 4: Tell Me When You're Done

Once you've completed Steps 1-3, let me know and I'll:
1. Create `NotificationManager.swift`
2. Create `AppDelegate.swift`
3. Update `GolfDadsApp.swift`
4. Update `NetworkService.swift`
5. Create the `NotificationPreferences` model

---

## Troubleshooting

**If Firebase package won't add:**
- Make sure you're adding it to the correct target ("GolfDads", not "GolfDadsTests")
- Try restarting Xcode
- Check your internet connection

**If GoogleService-Info.plist isn't recognized:**
- Make sure it's in the root of the GolfDads folder (not in a subfolder)
- Make sure it's added to the "GolfDads" target (check Target Membership in File Inspector)

---

**Next:** After manual Xcode steps are complete, I'll generate all the Swift code files! 🚀
