# Three Putt - Version 1.2.1 Build 4

**Release Date:** December 22, 2025

## Critical Bug Fix

### Push Notification Timezone
Push notifications now display tee times in your local timezone instead of UTC.

**Problem Fixed:**
- Users were receiving notifications showing UTC time instead of local time
- Example: Mountain Time user creating 10:15am tee time would see notification showing 5:15pm

**Solution:**
- App automatically sends device timezone during push token registration
- Backend formats notification times specifically for each device's timezone
- Timezone updates automatically when app launches (handles traveling users)
- No user setup required

**Technical Changes:**
- NetworkService: Sends TimeZone.current.identifier during device token registration
- NotificationManager: Re-registers token on app launch to keep timezone current
- Backend: Added timezone column to device_tokens table
- Backend: All notification jobs now format times per-device

## Additional Fixes

### Notification Preferences Bug
- Fixed bug where notification preferences failed to load with decoding error
- Fixed bug where 24-hour and 2-hour reminder toggles wouldn't turn off
- Problem: Swift's snake_case conversion doesn't handle numbered fields correctly
- Solution: Added explicit CodingKeys for proper field mapping between iOS and backend
- Notification preferences now load correctly and all toggles work as expected

### Group Join Error Handling
- Invalid invite codes now show proper error message instead of "internal server error"
- Added input sanitization for invite codes (whitespace trimming, case handling)
- Improved robustness with better exception handling

## Testing

- All 116 iOS tests passing (12 new NotificationPreferences tests added)
- All 604 backend tests passing (2 new notification preferences tests added)
- Comprehensive test coverage for timezone functionality
- Comprehensive test coverage for notification preferences encoding/decoding
- Tests cover edge cases and backward compatibility

## Backward Compatibility

- Old app versions (Builds 1-3) continue working without changes
- Devices without timezone information show UTC with "UTC" suffix until updated
- All API changes are additive and backward compatible

## Previous Version 1.2.1 Fixes

- Fixed critical issue preventing favorite courses from loading
- Fixed error preventing browse tee times from displaying
- Fixed group tee times loading failures
- Improved browse view by automatically hiding tee times older than 6 hours
