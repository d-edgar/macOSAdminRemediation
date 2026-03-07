# CNUAdminManager — Xcode Project Setup Guide

## Creating the Xcode Project

### Step 1: Create the Project
1. Open Xcode → **File → New → Project**
2. Choose **macOS → App**
3. Settings:
   - Product Name: `CNUAdminManager`
   - Team: Your Apple Developer team
   - Organization Identifier: `com.cnu`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Uncheck: Include Tests (add later if desired)
4. Save to your git repo directory

### Step 2: Add the App Source Files
Drag these folders/files into the `CNUAdminManager` target in Xcode:
- `CNUAdminManager/CNUAdminManagerApp.swift` (replace the generated one)
- `CNUAdminManager/ContentView.swift` (replace the generated one)
- `CNUAdminManager/Views/` (entire folder)
- `CNUAdminManager/Services/` (entire folder)
- `CNUAdminManager/Models/` (entire folder)
- `CNUAdminManager/Info.plist`

### Step 3: Add the Privileged Helper Target
1. **File → New → Target**
2. Choose **macOS → Command Line Tool**
3. Settings:
   - Product Name: `com.cnu.adminmanager.helper`
   - Language: **Swift**
4. Replace the generated `main.swift` with `CNUAdminHelper/CNUAdminHelper.swift`
5. Set the helper's **Build Settings**:
   - `INSTALL_PATH` = `/Library/PrivilegedHelperTools`
   - `SKIP_INSTALL` = `No`

### Step 4: Configure Build Settings

#### App Target:
- **Signing & Capabilities**: Sign with your Developer ID
- **Info.plist**: Point to `CNUAdminManager/Info.plist`
- **Deployment Target**: macOS 13.0+
- **Build Settings → Other Linker Flags**: Add `-framework IOKit`

#### Helper Target:
- **Signing & Capabilities**: Sign with your Developer ID
- **Deployment Target**: macOS 13.0+
- **Product Name**: `com.cnu.adminmanager.helper`

### Step 5: Framework Dependencies
The app uses these system frameworks (most are automatic with SwiftUI):
- `SwiftUI`
- `Foundation`
- `IOKit` (for serial number — add manually if needed)
- `OpenDirectory` (for account type detection)
- `os.log` (for unified logging)

Add any missing frameworks: Target → Build Phases → Link Binary With Libraries

## Building the PKG

### Prerequisites
- Xcode command line tools: `xcode-select --install`
- Developer ID signing certificate

### Build Steps
```bash
# 1. Build both targets in Release mode
xcodebuild -scheme CNUAdminManager -configuration Release build
xcodebuild -scheme com.cnu.adminmanager.helper -configuration Release build

# 2. Run the PKG builder
./Scripts/build-pkg.sh 1.0.0
```

The PKG will be output to `./build/CNUAdminManager-1.0.0.pkg`

## Jamf Pro Deployment

### Smart Groups

#### Smart Group 1: "Admin Users - Needs Remediation"
Criteria: Local Account is admin = Yes (use an Extension Attribute or Jamf inventory)

#### Smart Group 2: "Admin Users - Remediated"
Criteria: Local Account is admin = No (inverse of above)

### Policy 1: Deploy CNUAdminManager
- Trigger: Recurring Check-in
- Scope: Smart Group 1 ("Admin Users - Needs Remediation")
- Packages: Upload `CNUAdminManager-1.0.0.pkg`
- Frequency: Once per computer

### Policy 2: Deploy Configuration Profile
- Scope: Smart Group 1
- Configuration Profile: Upload `ConfigProfile/com.cnu.adminmanager.mobileconfig`
  OR create a Custom Settings profile with the keys from the example

### Policy 3: Uninstall (Cleanup)
- Trigger: Recurring Check-in
- Scope: Smart Group 2 ("Admin Users - Remediated")
- Scripts: Upload `Scripts/uninstall.sh`
- Frequency: Once per computer

## File Locations on Target Macs

| Component | Path |
|-----------|------|
| App | `/Library/Application Support/CNUAdminManager/CNUAdminManager.app` |
| Helper | `/Library/PrivilegedHelperTools/com.cnu.adminmanager.helper` |
| LaunchDaemon | `/Library/LaunchDaemons/com.cnu.adminmanager.helper.plist` |
| LaunchAgent | `/Library/LaunchAgents/com.cnu.adminmanager.plist` |
| Audit Log | `/Library/Logs/CNUAdminManager.log` |
| Signal Dir | `/Library/Application Support/CNUAdminManager/` |

## Configuration Profile Keys

All keys are optional. Set them via Jamf Custom Settings targeting domain `com.cnu.adminmanager`:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| OrganizationName | String | CNU | Org name in UI |
| SupportRequestURL | String | https://support.cnu.edu/admin-request | Ticket submission URL |
| SupportEmail | String | itsupport@cnu.edu | Support contact email |
| PolicyMessage | String | (default text) | Custom policy warning |
| NagIntervalSeconds | Integer | 14400 | Display interval (info only) |
| AllowDeferral | Boolean | false | Let users close without acting |
| GracePeriodDays | Integer | 0 | Days before forced remediation |
| ShowSubmitRequestOption | Boolean | true | Show "Submit Request" button |
| JamfConnectAppPath | String | /Applications/Jamf Connect.app | Path to detect Jamf Connect |
| EnableLocalAuditLog | Boolean | true | Write local audit log |
| AuditLogPath | String | /Library/Logs/CNUAdminManager.log | Audit log location |
