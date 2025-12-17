# Three Putt - Version 1.2.1 Release Notes

**Release Date:** December 16, 2024
**Build:** 1.2.1

## Overview

Version 1.2.1 is a critical bug fix release that resolves API communication issues that were preventing the app from loading tee times and favorite courses. This release also improves the browse experience by automatically hiding old past tee times.

---

## Bug Fixes

### 🐛 Fixed Critical API Decoding Errors

**Issue:** The app was experiencing multiple crashes and failures when loading data from the API:
- Favorite courses wouldn't load
- Browse tee times failed to display
- Group tee times showed errors

**Root Cause:** Missing JSON decoder configuration caused a mismatch between the API's response format (snake_case) and the app's expected format (camelCase).

**Fix:**
- Enabled automatic snake_case to camelCase conversion in the network layer
- Updated all model definitions to use the automatic conversion
- Added comprehensive tests to prevent this issue in the future

**Impact:** All API endpoints now work reliably, and data loads correctly throughout the app.

---

## Improvements

### ✨ Automatic Cleanup of Old Tee Times

**What Changed:** Tee times older than 6 hours are now automatically hidden from browse and group views.

**Why:** This keeps the tee time list relevant and focused on upcoming opportunities, rather than cluttered with old past events.

**Behavior:**
- Tee times remain visible for 6 hours after their scheduled time
- After 6 hours, they automatically stop appearing
- This happens server-side, so all users see the same filtered view

**Example:** A tee time scheduled for 2:00 PM will be visible until 8:00 PM, then automatically disappear.

---

## Technical Details

### API Communication Fixed

- Resolved `keyNotFound` decoding errors for:
  - `golf_courses` → `golfCourses`
  - `tee_time_postings` → `teeTimePostings`
  - `user_id` → `userId`
  - And all other snake_case/camelCase mismatches

### Test Coverage

- Added 11 new iOS tests for API response decoding
- All tests passing
- Regression tests included to prevent future occurrences

### Models Updated

Updated decoding logic for:
- TeeTimePosting
- GolfCourseInfo
- ReservationInfo
- Group
- GroupMember
- Reservation
- NotificationPreferences

---

## Upgrade Notes

- **Recommended:** This is a critical bug fix release. All users should update.
- **No Breaking Changes:** All existing features continue to work as expected
- **No Data Loss:** Your favorite courses, groups, and tee times are preserved

---

## Previous Version (1.2)

For reference, version 1.2 included:
- Push notifications foundation (Phase 4)
- Profile location preferences (home zip code, search radius)
- Favorite golf courses
- Group owner privileges
- Manual golf course entry
- Golf course search with autocomplete
- My Reservations section

---

## Known Issues

None at this time.

---

## Support

If you experience any issues with this release, please report them through the app or contact support.

---

## Coming Soon

See [NEXT_FEATURES.md](../docs/NEXT_FEATURES.md) for upcoming enhancements including:
- Universal Links (professional share URLs)
- Push notifications (reservations, reminders, group activity)
- Map view for tee times
- Weather forecast integration

---

**Thank you for using Three Putt!**
