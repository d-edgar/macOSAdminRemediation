# Contributing to Admin Rights Manager

Thanks for your interest in contributing! Here's how to get started.

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 16+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (recommended) or manual project setup

## Project Setup

### Quick Start (xcodegen)

```bash
brew install xcodegen
xcodegen generate
open AdminRightsManager.xcodeproj
```

This generates a project with two targets already wired up:

- **AdminRightsManager** — the SwiftUI app
- **com.adminrights.manager.helper** — the privileged helper (LaunchDaemon)

### Manual Xcode Setup (alternative)

#### Step 1: Create the Project
1. Open Xcode → **File → New → Project**
2. Choose **macOS → App**
3. Settings:
   - Product Name: `AdminRightsManager`
   - Team: Your Apple Developer team
   - Organization Identifier: `com.adminrights`
   - Interface: **SwiftUI**
   - Language: **Swift**
4. Save to your repo directory

#### Step 2: Add the App Source Files
Drag these into the `AdminRightsManager` target:
- `AdminRightsManager/AdminRightsManagerApp.swift`
- `AdminRightsManager/ContentView.swift`
- `AdminRightsManager/Views/`
- `AdminRightsManager/Services/`
- `AdminRightsManager/Models/`
- `AdminRightsManager/Info.plist`

#### Step 3: Add the Privileged Helper Target
1. **File → New → Target**
2. Choose **macOS → Command Line Tool**
3. Product Name: `com.adminrights.manager.helper`
4. Replace `main.swift` with `AdminRightsHelper/AdminRightsHelper.swift`
5. Set Build Settings:
   - `INSTALL_PATH` = `/Library/PrivilegedHelperTools`
   - `SKIP_INSTALL` = `No`

#### Step 4: Framework Dependencies
Add any missing frameworks: Target → Build Phases → Link Binary With Libraries
- `IOKit` (for serial number)
- `OpenDirectory` (for account type detection)

## Building the PKG

```bash
xcodebuild -scheme AdminRightsManager -configuration Release build
xcodebuild -scheme com.adminrights.manager.helper -configuration Release build
./Scripts/build-pkg.sh 1.0.0
```

Output: `./build/AdminRightsManager-1.0.0.pkg`

## Configuration Profile Keys

All keys are optional. Deploy via MDM Custom Settings targeting domain `com.adminrights.manager`:

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

## Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes
4. Push to your branch and open a pull request

## Reporting Issues

If you find a bug or have a feature request, please [open an issue](../../issues) with as much detail as possible — macOS version, MDM solution, and steps to reproduce are especially helpful.
