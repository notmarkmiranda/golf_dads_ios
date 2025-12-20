# Add New Files to Xcode Project

Please add these new files to the Xcode project:

## Main App Target (GolfDads)
1. **AuthenticationManager.swift**
   - Path: `GolfDads/Managers/AuthenticationManager.swift`
   - Target: GolfDads (main app)
   - Folder: Create "Managers" group if it doesn't exist

## Test Target (GolfDadsTests)
1. **MockAuthenticationService.swift**
   - Path: `GolfDadsTests/Mocks/MockAuthenticationService.swift`
   - Target: GolfDadsTests only
   - Folder: Mocks group

2. **AuthenticationManagerTests.swift**
   - Path: `GolfDadsTests/ManagerTests/AuthenticationManagerTests.swift`
   - Target: GolfDadsTests only
   - Folder: Create "ManagerTests" group if it doesn't exist

## Steps to Add Files:
1. In Xcode, right-click on the appropriate group
2. Select "Add Files to GolfDads..."
3. Navigate to the file
4. **Important**: Uncheck "Copy items if needed" (files are already in the right location)
5. Select the correct target (GolfDads or GolfDadsTests)
6. Click "Add"

After adding, run tests with: Cmd+U
