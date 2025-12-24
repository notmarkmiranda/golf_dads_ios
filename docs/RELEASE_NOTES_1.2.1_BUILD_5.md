# Three Putt - Version 1.2.1 Build 5

**Release Date:** December 23, 2025

## Bug Fixes

### Notification Preferences
- Fixed bug where notification preferences failed to load with decoding error
- Fixed bug where 24-hour and 2-hour reminder toggles wouldn't turn off
- Problem: Swift's snake_case conversion doesn't handle numbered fields correctly
- Solution: Added explicit CodingKeys for proper field mapping between iOS and backend
- All notification preference toggles now work correctly

### My Tee Times Screen
- Automatically hide tee times older than 6 hours from My Postings and My Reservations
- Sort tee times chronologically with soonest tee time first
- Keeps your tee time list focused on upcoming golf rounds

## Testing

- iOS tests: 116 passing (12 new NotificationPreferences tests added)
- Backend tests: 604 passing (2 new notification preferences tests added)
- Comprehensive test coverage for encoding/decoding

## Previous Builds

### Build 4 (December 23, 2025)
- Fixed push notification timezone bug (notifications now show local time instead of UTC)
