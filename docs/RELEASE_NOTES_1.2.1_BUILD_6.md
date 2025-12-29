# Three Putt - Version 1.2.1 Build 6

**Release Date:** December 23, 2025

## Bug Fixes

### Favorite Courses Screen (iOS 26)
- Fixed layout issue where table was centered instead of top-aligned on iOS 26
- Fixed navigation header disappearing
- Used GeometryReader to force proper frame dimensions on iOS 26
- Removed nested NavigationStack that caused layout conflicts

### Create Tee Time from Favorites
- Fixed + button showing blank screen instead of Create Tee Time form
- Changed from .sheet(isPresented:) to .sheet(item:) for reliable presentation
- Tapping + now properly opens Create Tee Time with the course pre-selected

### View All Favorites Dismiss
- Fixed "something went wrong" error when swiping to dismiss Favorites sheet
- Added NavigationStack wrapper when presented as standalone sheet
- Added Done button for explicit dismissal from Create Tee Time view

## Technical Changes

### iOS
- FavoriteCoursesView: Added GeometryReader with explicit frame constraints
- FavoriteCoursesView: Added showCloseButton parameter for sheet presentation mode
- FavoriteCoursesView: Changed sheet presentation to use item binding instead of isPresented
- FavoriteCoursesView: Conditional NavigationStack wrapper for sheet mode

### Backend
- No backend changes in this build

## Testing

- iOS: 117 tests passing (3 known flaky Google Auth tests)
- Backend: 604 tests passing, 0 failures
- Tested on iOS 26.2 simulator (iPhone 17 Pro Max)
- Fixed 2 timezone test failures using relative dates

## Previous Builds

### Build 5 (December 23, 2025)
- Fixed notification preferences loading and toggle bugs

### Build 4 (December 23, 2025)
- Fixed push notification timezone bug
