# Adding Files to Xcode Project

Since we created files outside of Xcode, they need to be added to the project.

## Files Created So Far

### Main App Target (GolfDads)
- `GolfDads/Services/APIConfiguration.swift`
- `GolfDads/Utils/APIError.swift`

### Test Target (GolfDadsTests)
- `GolfDadsTests/ServiceTests/APIConfigurationTests.swift`

## How to Add Files to Xcode

### Option 1: Drag and Drop (Easiest)

1. Open **Finder** and navigate to `/Users/weatherby/Development/golf_dads/GolfDads/`
2. Open **Xcode** with the GolfDads project
3. In Finder, locate `GolfDads/Services/APIConfiguration.swift`
4. **Drag the file** from Finder into Xcode's project navigator
5. Drop it under the **GolfDads** folder
6. In the dialog that appears:
   - ✅ Check **"Copy items if needed"** (it should say "Don't copy" since it's already there)
   - ✅ Check **"Create groups"**
   - ✅ Make sure **"GolfDads"** target is selected
   - Click **"Finish"**
7. Repeat for `GolfDads/Utils/APIError.swift`
8. Repeat for test file, but select **"GolfDadsTests"** target instead

### Option 2: Add Files Menu

1. In Xcode, **right-click** on the **"GolfDads"** group (yellow folder)
2. Select **"Add Files to 'GolfDads'..."**
3. Navigate to the `GolfDads/Services/` folder
4. Select `APIConfiguration.swift`
5. Make sure:
   - ✅ **"Add to targets: GolfDads"** is checked
   - ✅ **"Create groups"** is selected
6. Click **"Add"**
7. Repeat for other files

### Option 3: Re-create Folders in Xcode (Most Organized)

Since we created folder structures that Xcode doesn't know about yet:

1. **In Xcode**, right-click on **"GolfDads"** group
2. Select **"New Group"**, name it **"Services"**
3. Right-click on the new **"Services"** group
4. Select **"Add Files to 'GolfDads'..."**
5. Navigate to `GolfDads/Services/APIConfiguration.swift`
6. Add it to the Services group
7. Repeat for other folders:
   - Create **"Utils"** group → add `APIError.swift`
   - In **GolfDadsTests**, create **"ServiceTests"** group → add test files

## Verify Files Are Added

After adding files:

1. Select a file in Xcode's project navigator
2. Open the **File Inspector** (right sidebar, first tab)
3. Under **"Target Membership"**, verify:
   - Source files: ✅ **GolfDads** checked
   - Test files: ✅ **GolfDadsTests** checked

## Build and Test

After adding files:

1. **Clean** build folder: **Product → Clean Build Folder** (Cmd + Shift + K)
2. **Build**: **Product → Build** (Cmd + B)
3. **Run tests**: **Product → Test** (Cmd + U)

---

**Note:** Once files are added to Xcode, we can continue creating more Phase 2 files and they'll work properly with the build system.
