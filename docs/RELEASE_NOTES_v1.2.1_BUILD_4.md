# Release Notes - Version 1.2.1 Build 4

**Release Date:** December 22, 2025
**Build Number:** 4
**Version:** 1.2.1

## Critical Bug Fix: Push Notification Timezone

### Problem Fixed
Push notifications were displaying tee times in UTC instead of users' local timezones, causing significant confusion. For example, a user in Mountain Time creating a tee time for 10:15am would receive a notification showing 5:15pm (the UTC time).

### Solution Implemented
The app now automatically sends the device's timezone during push notification registration and updates it every time the app launches. The backend formats all notification times specifically for each device's timezone.

### What This Means for Users
- **Notifications now show correct local times** - Mountain Time users see times in MST, Pacific users see PST, etc.
- **Automatic timezone updates** - If you travel to a different timezone, your next notification will show the correct local time
- **No user action required** - Everything happens automatically in the background
- **Backward compatible** - Older app versions continue working (showing UTC with "UTC" suffix)

### Technical Details

**iOS Changes:**
- NetworkService: Sends `TimeZone.current.identifier` (e.g., "America/Denver") during device token registration
- NotificationManager: Re-registers device token every time app becomes active to keep timezone current

**Backend Changes:**
- New `timezone` column in `device_tokens` table stores each device's timezone
- PushNotificationService formats times per-device using stored timezone information
- All notification jobs (group activity, tee time reminders) now format times individually for each recipient's device
- Comprehensive test coverage added (602 tests passing)

**Notification Format Examples:**

*Before Fix:*
```
Title: Golf Buddies
Body: Bob posted a tee time at Pine Valley on Dec 25 at 5:15pm
(Shows UTC time - wrong for most users)
```

*After Fix (Mountain Time):*
```
Title: Golf Buddies
Body: Bob posted a tee time at Pine Valley on Dec 25 at 10:15am
(Shows correct local time)
```

*After Fix (Pacific Time):*
```
Title: Golf Buddies
Body: Bob posted a tee time at Pine Valley on Dec 25 at 9:15am
(Each user sees their own timezone)
```

### Implementation Checklist

**Backend Deployment:**
- [ ] Run database migration to add timezone column
- [ ] Deploy backend code to production
- [ ] Verify migration successful
- [ ] Monitor for timezone validation errors

**iOS Deployment:**
- [ ] Increment build number to 4
- [ ] Update marketing version to 1.2.1
- [ ] Build and archive for TestFlight
- [ ] Upload to App Store Connect
- [ ] Submit for TestFlight review
- [ ] Distribute to testers

**Testing:**
- [ ] Test with devices in different timezones
- [ ] Verify old app versions still receive notifications (with UTC suffix)
- [ ] Verify new app versions receive local time notifications
- [ ] Test timezone updates when traveling (change device timezone, relaunch app, verify next notification)
- [ ] Monitor notification delivery rates

### Files Modified

**Backend (golf_api):**
- `db/migrate/20251222034205_add_timezone_to_device_tokens.rb` (new)
- `app/models/device_token.rb`
- `app/controllers/api/v1/device_tokens_controller.rb`
- `app/services/push_notification_service.rb`
- `app/jobs/group_activity_notification_job.rb`
- `app/jobs/tee_time_reminder_job.rb`
- Comprehensive test updates in `spec/` directory

**iOS (GolfDads):**
- `GolfDads/Services/NetworkService.swift`
- `GolfDads/Managers/NotificationManager.swift`

**Documentation:**
- `docs/PUSH_NOTIFICATION_TIMEZONE_FIX.md` (new - comprehensive implementation guide)

## Testing

**Backend:**
- All 602 RSpec tests passing
- Timezone validation tests
- Per-device formatting tests
- Notification job tests updated

**iOS:**
- All 104 XCTests passing
- NetworkService tests cover timezone parameter
- Existing tests verify backward compatibility

## Upgrade Notes

**For Existing Users:**
- Update will install automatically or when user updates from App Store
- First app launch after update will register device timezone
- Subsequent notifications will display in correct local time
- No user action required - completely automatic

**For New Users:**
- Timezone automatically registered on first app launch
- All notifications show correct local time from the start

**Backward Compatibility:**
- Old app versions (builds 1-3) continue working without changes
- Old devices receive UTC time with "UTC" suffix until they update
- API changes are fully backward compatible

## Related Documentation

- [PUSH_NOTIFICATION_TIMEZONE_FIX.md](PUSH_NOTIFICATION_TIMEZONE_FIX.md) - Complete implementation details
- [PUSH_NOTIFICATIONS_PHASE_4_COMPLETE.md](PUSH_NOTIFICATIONS_PHASE_4_COMPLETE.md) - Original push notification setup
- [SOLID_QUEUE_SETUP.md](SOLID_QUEUE_SETUP.md) - Background job configuration

## Success Metrics

**Week 1 Targets:**
- 80%+ of active users on build 4 within 7 days
- Zero increase in notification delivery failures
- <1% timezone validation errors in backend logs

**Week 2-4 Targets:**
- 90%+ adoption
- Reduced user confusion (monitor support tickets)
- Positive user feedback on notification accuracy

## Known Issues

None at this time. This release specifically addresses the timezone display bug.

## Next Release Preview

Upcoming features being considered:
- Group join requests (pending invitations)
- Enhanced tee time filters
- Course reviews and ratings
- Weather integration

---

**Questions or Issues?**
Contact: [your contact info]

**Build Information:**
- Version: 1.2.1
- Build: 4
- iOS Minimum: 17.0
- Xcode Version: 16+
- Swift Version: 6.0
