# Admin Rights Manager

A macOS tool for managing and remediating unauthorized admin privileges. Deployed as a signed and notarized `.pkg` via MDM (Jamf Pro, Mosyle, Kandji, etc.), it detects users with admin rights, presents a compliance nag window on a recurring schedule, and provides self-service remediation or an elevation request workflow.

Fully white-label — customize branding, colors, logos, messaging, and support URLs via MDM configuration profiles.

## How It Works

Admin Rights Manager has three components that work together:

- **LaunchAgent** — Runs in the logged-in user's session. Launches the app at login and on a recurring interval (default: every 4 hours). Installed to `/Library/LaunchAgents/`.
- **App** (`AdminRightsManager.app`) — A SwiftUI window that checks whether the current user has admin rights. If they do, it displays a branded compliance nag with options to self-remediate or submit a request for continued access. If the user is not an admin, the app quits immediately. Installed to `/Library/Application Support/AdminRightsManager/`. Hidden from the Dock via `LSUIElement`.
- **Privileged Helper** — A LaunchDaemon running as root that performs the actual admin rights removal using `dseditgroup`. The app communicates with it via a file-based signal in `/Library/Application Support/AdminRightsManager/`. Installed to `/Library/PrivilegedHelperTools/`.

## Requirements

- macOS 13.0 (Ventura) or later
- MDM solution capable of deploying `.pkg` files and configuration profiles
- Apple Developer ID certificates for signing (Application + Installer)

## Building the PKG

### Automated (GitHub Actions)

The repository includes a GitHub Actions workflow that builds, signs, notarizes, and publishes the `.pkg` automatically.

**Trigger via tag:**

```bash
git tag -a v1.0.1 -m "Release v1.0.1"
git push origin v1.0.1
```

**Trigger manually:** Go to Actions → "Build & Sign PKG" → "Run workflow" and enter a version number.

The workflow produces a signed, notarized `.pkg` attached as both a build artifact and a GitHub Release.

**Required repository secrets:**

| Secret | Description |
|--------|-------------|
| `DEVELOPER_ID_APP_CERTIFICATE_P12` | Base64-encoded Developer ID Application `.p12` |
| `DEVELOPER_ID_INSTALLER_CERTIFICATE_P12` | Base64-encoded Developer ID Installer `.p12` |
| `CERTIFICATE_PASSWORD` | Export password for the `.p12` files |
| `KEYCHAIN_PASSWORD` | Any random string (temporary keychain on the runner) |
| `DEVELOPER_ID_NAME` | Signing identity name, e.g. `Your Name (TEAMID)` |
| `APPLE_ID` | Apple ID email for notarization |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password from appleid.apple.com |
| `APPLE_TEAM_ID` | 10-character Apple Developer Team ID |

### Manual

1. Open `AdminRightsManager.xcodeproj` in Xcode 16+
2. Build the `AdminRightsManager` scheme (Release configuration)
3. Build the `com.adminrights.manager.helper` scheme (Release configuration)
4. Run the build script from the project root:

```bash
./Scripts/build-pkg.sh 1.0.1
```

The output `.pkg` will be in `./build/`. Sign and notarize it before deploying.

## Deploying via MDM

### Step 1: Upload the PKG

Upload `AdminRightsManager-x.x.x.pkg` to your MDM as a package. In Jamf Pro, this goes under Settings → Packages.

### Step 2: Deploy the Configuration Profile

The file `ConfigProfile/com.adminrights.manager.mobileconfig` is a template for customizing the tool's behavior. Before deploying:

1. Update all values marked `CHANGE THIS` — at minimum: `OrganizationName`, `SupportContactName`, `SupportEmail`, and `PolicyMessage`
2. Generate new `PayloadUUID` values using `uuidgen` in Terminal
3. Upload to your MDM as a Custom Settings / Configuration Profile targeting the `com.adminrights.manager` preference domain
4. Scope it to the same group as the PKG

**Configurable settings include:**

- Organization name, department name, and brand colors (primary, secondary, dark — as hex values)
- Custom logo image path
- Support contact info (phone, email, website, request portal URL)
- Policy message text and policy document URL
- Nag behavior: deferral allowed, grace period in days, nag interval
- Show/hide the "Submit Request" button
- Jamf Connect integration paths
- Audit logging toggle and log path

All keys are optional — the app uses sensible defaults for anything not specified in the profile.

### Step 3: Create a Smart Group

Create a smart group in your MDM that targets machines where the logged-in user has admin rights. Scope both the PKG policy and the configuration profile to this group.

### Step 4: Uninstall Policy (Optional)

For users who have been remediated (no longer admins), create a separate policy scoped to a "remediated" smart group that runs the uninstall script:

```bash
./Scripts/uninstall.sh
```

This removes the app, helper, LaunchDaemon, LaunchAgent, and all supporting files.

## File Locations

| Component | Path |
|-----------|------|
| App bundle | `/Library/Application Support/AdminRightsManager/AdminRightsManager.app` |
| Privileged helper | `/Library/PrivilegedHelperTools/com.adminrights.manager.helper` |
| LaunchDaemon plist | `/Library/LaunchDaemons/com.adminrights.manager.helper.plist` |
| LaunchAgent plist | `/Library/LaunchAgents/com.adminrights.manager.plist` |
| Audit log | `/Library/Logs/AdminRightsManager.log` |
| Helper stdout log | `/Library/Logs/AdminRightsManager-helper.log` |

## Preference Domain

`com.adminrights.manager`

The app reads its configuration from managed preferences via `UserDefaults`. Any key set through an MDM configuration profile targeting this domain will override the built-in defaults. See the `.mobileconfig` template for the full list of available keys.

## License

See [LICENSE](LICENSE) for details.
