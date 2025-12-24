# Three Putt - Version 1.2.1 Build 5

**Release Date:** December 23, 2025

## Bug Fixes

### Notification Preferences
- Fixed bug where notification preferences failed to load with decoding error
- Fixed bug where 24-hour and 2-hour reminder toggles wouldn't turn off
- Problem: Swift's snake_case conversion doesn't handle numbered fields correctly
- Solution: Added explicit CodingKeys for proper field mapping between iOS and backend
- All notification preference toggles now work correctly

## Testing

- All 116 iOS tests passing (12 new NotificationPreferences tests added)
- All 604 backend tests passing (2 new notification preferences tests added)
- Comprehensive test coverage for encoding/decoding

## Previous Builds

### Build 4 (December 23, 2025)
Push notifications now display tee times in your local timezone instead of UTC.

**Problem Fixed:**
- Users were receiving notifications showing UTC time instead of local time
- Example: Mountain Time user creating 10:15am tee time would see notification showing 5:15pm

**Solution:**
- App automatically sends device timezone during push token registration
- Backend formats notification times specifically for each device's timezone
- Timezone updates automatically when app launches (handles traveling users)
- No user setup required

### Build 3 and Earlier
- Fixed critical issue preventing favorite courses from loading
- Fixed error preventing browse tee times from displaying
- Fixed group tee times loading failures
- Improved browse view by automatically hiding tee times older than 6 hours
- Improved group join error handling
