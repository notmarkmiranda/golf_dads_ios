# Three Putt - Version 1.2.1 Build 6

**Release Date:** December 23, 2025

## Bug Fixes

### Favorite Courses Screen
- Fixed layout issue on iOS 26 where table appeared centered instead of at the top
- Fixed navigation header disappearing on iOS 26
- Fixed + button showing blank screen - now properly opens Create Tee Time with course pre-selected
- Fixed error when dismissing Favorites list from Create Tee Time screen

## Testing

- 117 iOS tests passing
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
