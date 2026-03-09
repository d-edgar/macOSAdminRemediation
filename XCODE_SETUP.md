# Admin Rights Manager — Xcode Project Setup Guide

## Quick Start (xcodegen)

```bash
# Install xcodegen if you don't have it
brew install xcodegen

# Generate the Xcode project from the repo root
xcodegen generate

# Open the project
open AdminRightsManager.xcodeproj
```

This generates a project with two targets already wired up:
- **AdminRightsManager** — the SwiftUI app
- **com.adminrights.manager.helper** — the privileged helper (LaunchDaemon)

## Manual Xcode Setup (alternative)

### Step 1: Create the Project
1. Open Xcode → **File → New → Project**
2. Choose **macOS → App**
3. Settings:
   - Product Name: `AdminRightsManager`
   - Team: Your Apple Developer team
   - Organization Identifier: `com.adminrights`
   - Interface: **SwiftUI**
   - Language: **Swift**
4. Save to your repo directory

### Step 2: Add the App Source Files
Drag these into the `AdminRightsManager` target:
- `AdminRightsManager/AdminRightsManagerApp.swift`
- `AdminRightsManager/ContentView.swift`
- `AdminRightsManager/Views/`
- `AdminRightsManager/Services/`
- `AdminRightsManager/Models/`
- `AdminRightsManager/Info.plist`

### Step 3: Add the Privileged Helper Target
1. **File → New → Target**
2. Choose **macOS → Command Line Tool**
3. Product Name: `com.adminrights.manager.helper`
4. Replace `main.swift` with `AdminRightsHelper/AdminRightsHelper.swift`
5. Set Build Settings:
   - `INSTALL_PATH` = `/Library/PrivilegedHelperTools`
   - `SKIP_INSTALL` = `No`

### Step 4: Framework Dependencies
Add any missing frameworks: Target → Build Phases → Link Binary With Libraries
- `IOKit` (for serial number)
- `OpenDirectory` (for account type detection)

## Building the PKG

```bash
# Build both targets in Release mode
xcodebuild -scheme AdminRightsManager -configuration Release build
xcodebuild -scheme com.adminrights.manager.helper -configuration Release build

# Build the PKG
./Scripts/build-pkg.sh 1.0.0
```

Output: `./build/AdminRightsManager-1.0.0.pkg`

## Jamf Pro Deployment

### Smart Groups

**Smart Group 1: "Admin Users - Needs Remediation"**
Criteria: Local account has admin rights (via Extension Attribute)

**Smart Group 2: "Admin Users - Remediated"**
Criteria: Local account does NOT have admin rights

### Policies

| Policy | Trigger | Scope | Payload |
|--------|---------|-------|---------|
| Deploy | Recurring Check-in | Smart Group 1 | `AdminRightsManager-1.0.0.pkg` |
| Configure | Recurring Check-in | Smart Group 1 | Config profile (`.mobileconfig`) |
| Uninstall | Recurring Check-in | Smart Group 2 | `Scripts/uninstall.sh` |

## File Locations on Target Macs

| Component | Path |
|-----------|------|
| App | `/Library/Application Support/AdminRightsManager/AdminRightsManager.app` |
| Helper | `/Library/PrivilegedHelperTools/com.adminrights.manager.helper` |
| LaunchDaemon | `/Library/LaunchDaemons/com.adminrights.manager.helper.plist` |
| LaunchAgent | `/Library/LaunchAgents/com.adminrights.manager.plist` |
| Audit Log | `/Library/Logs/AdminRightsManager.log` |

## Configuration Profile Keys

All keys are optional. Deploy via Jamf Custom Settings targeting domain `com.adminrights.manager`:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| OrganizationName | String | Your Organization | Org name in UI |
| DepartmentName | String | IT Services | Department shown in header |
| PrimaryColorHex | String | #1b386d | Primary brand color |
| SecondaryColorHex | String | #84888b | Secondary brand color |
| DarkColorHex | String | #172951 | Dark background color |
| LogoImagePath | String | (empty) | Path to custom logo PNG |
| SupportRequestURL | String | (HelpSpot URL) | Ticket portal URL |
| SupportEmail | String | helpdesk@example.edu | Support contact email |
| PolicyMessage | String | (default text) | Policy warning message |
| NagIntervalSeconds | Integer | 14400 | Display interval (info only) |
| AllowDeferral | Boolean | false | Let users close without acting |
| GracePeriodDays | Integer | 0 | Days before forced remediation |
| ShowSubmitRequestOption | Boolean | true | Show "Submit Request" button |
| JamfConnectAppPath | String | /Applications/Jamf Connect.app | Path to detect Jamf Connect |
| EnableLocalAuditLog | Boolean | true | Write local audit log |
| AuditLogPath | String | /Library/Logs/AdminRightsManager.log | Audit log location |
