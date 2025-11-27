# TODO: Fix Email Placeholder Color in Dark Mode

## Issue
The email TextField placeholder text appears blue in dark mode, making it look like the field is already filled in. Other fields (name, password) display correctly with gray placeholders.

## Location
- `LoginView.swift` - Email TextField (lines 52-70)
- `SignUpView.swift` - Email TextField (lines 73-91)

## Attempted Fixes
1. Added `.foregroundStyle(.primary)` - didn't work, made it worse
2. Used `prompt` parameter with `.foregroundColor(.secondary)` - didn't work for email field
3. Created custom placeholder using ZStack with conditional Text - still showing blue

## Notes
- The issue is specific to the email field
- `.textContentType(.emailAddress)` and `.keyboardType(.emailAddress)` might be interfering
- Other TextFields (name, password) work correctly with standard placeholders
- Issue only visible in dark mode on physical device
- User reported it's not critical, moved on to continue with UI development

## Next Steps to Try
1. Test without `.textContentType(.emailAddress)` to see if that's the cause
2. Try using UIKit's UITextField with UIViewRepresentable for more control
3. Check if it's an iOS version-specific issue
4. File a bug report with Apple if it's a SwiftUI bug
