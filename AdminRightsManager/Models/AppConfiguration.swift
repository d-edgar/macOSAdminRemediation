//
//  AppConfiguration.swift
//  AdminRightsManager
//
//  Reads managed preferences from Jamf Configuration Profiles.
//  Admins can customize behavior by deploying a config profile
//  targeting the preference domain: com.adminrights.manager
//

import Foundation
import os.log

struct AppConfiguration {
    static let bundleIdentifier = "com.adminrights.manager"
    static let shared = AppConfiguration()

    private let defaults: UserDefaults
    private let logger = Logger(subsystem: bundleIdentifier, category: "Configuration")

    init() {
        // UserDefaults reads managed preferences set by MDM config profiles
        // automatically from the app's preference domain.
        self.defaults = UserDefaults.standard
        logger.info("Configuration loaded from managed preferences domain: \(Self.bundleIdentifier)")
    }

    // MARK: - Organization Branding

    /// Organization name displayed in the nag window
    var organizationName: String {
        defaults.string(forKey: "OrganizationName") ?? "IT Services"
    }

    // MARK: - Support Contact Information

    /// Display name for the support team (e.g., "IT Help Desk", "Tech Support")
    var supportContactName: String {
        defaults.string(forKey: "SupportContactName") ?? "IT Help Desk"
    }

    /// Support phone number displayed in the app
    var supportPhone: String {
        defaults.string(forKey: "SupportPhone") ?? "(555) 123-4567"
    }

    /// Support email for questions
    var supportEmail: String {
        defaults.string(forKey: "SupportEmail") ?? "helpdesk@example.com"
    }

    /// General IT website/portal URL (e.g., "https://it.example.edu")
    var supportWebsiteURL: String {
        defaults.string(forKey: "SupportWebsiteURL") ?? "https://www.google.com"
    }

    /// URL for submitting admin rights elevation requests (e.g., help desk ticket portal)
    var supportRequestURL: String {
        defaults.string(forKey: "SupportRequestURL") ?? "https://www.google.com"
    }

    /// Returns true if at least one support contact method is configured
    var hasAnySupportContact: Bool {
        !supportEmail.isEmpty || !supportWebsiteURL.isEmpty || !supportPhone.isEmpty
    }

    /// URL to the full admin rights policy document (shown as link in header)
    var policyURL: String {
        defaults.string(forKey: "PolicyURL") ?? "https://www.google.com"
    }

    /// Custom policy message shown in the nag window
    var policyMessage: String {
        defaults.string(forKey: "PolicyMessage") ??
        """
        Your account currently has administrator privileges on this Mac. \
        Per organizational policy, standard user accounts should not retain persistent \
        admin rights. This poses a security risk to your device and the network.
        """
    }

    // MARK: - Behavior Settings

    /// Nag interval in seconds (default: 4 hours = 14400 seconds)
    /// This is controlled by the LaunchAgent, but the app reads it for display purposes.
    var nagIntervalSeconds: Int {
        let value = defaults.integer(forKey: "NagIntervalSeconds")
        return value > 0 ? value : 14400
    }

    /// Human-readable nag interval for display
    var nagIntervalDescription: String {
        let hours = nagIntervalSeconds / 3600
        if hours == 1 {
            return "every hour"
        } else if hours > 0 {
            return "every \(hours) hours"
        } else {
            let minutes = nagIntervalSeconds / 60
            return "every \(minutes) minutes"
        }
    }

    /// Whether the user can defer/snooze (close the window without action)
    /// Default: false — window stays floating until they choose an option
    var allowDeferral: Bool {
        defaults.bool(forKey: "AllowDeferral")
    }

    /// Grace period in days before forced remediation (0 = no grace period)
    var gracePeriodDays: Int {
        let value = defaults.integer(forKey: "GracePeriodDays")
        return value >= 0 ? value : 0
    }

    /// Whether to show the "Submit Request" option
    /// Set to false if you don't want users to be able to request elevation
    var showSubmitRequestOption: Bool {
        let value = defaults.object(forKey: "ShowSubmitRequestOption")
        // Default to true if not set
        return (value as? Bool) ?? true
    }

    // MARK: - Branding — Appearance

    /// Department name shown in the header (e.g., "IT Services", "IT Security", "Help Desk")
    var departmentName: String {
        defaults.string(forKey: "DepartmentName") ?? "IT Services"
    }

    /// Primary brand color hex (e.g., "#1b386d")
    /// Used for buttons, accents, info boxes
    var primaryColorHex: String {
        defaults.string(forKey: "PrimaryColorHex") ?? "#1b386d"
    }

    /// Secondary/silver brand color hex (e.g., "#84888b")
    /// Used for secondary buttons and muted UI elements
    var secondaryColorHex: String {
        defaults.string(forKey: "SecondaryColorHex") ?? "#84888b"
    }

    /// Dark brand color hex (e.g., "#172951")
    /// Used for backgrounds and deep UI surfaces
    var darkColorHex: String {
        defaults.string(forKey: "DarkColorHex") ?? "#172951"
    }

    /// Path to a custom logo image file on disk (PNG recommended)
    /// If empty or file not found, falls back to the SF Symbol shield icon
    var logoImagePath: String {
        defaults.string(forKey: "LogoImagePath") ?? ""
    }

    // MARK: - Jamf Connect Integration

    /// Expected Jamf Connect app path for detection
    var jamfConnectAppPath: String {
        defaults.string(forKey: "JamfConnectAppPath") ?? "/Applications/Jamf Connect.app"
    }

    /// Jamf Connect elevation workflow URL (if applicable)
    var jamfConnectElevationURL: String {
        defaults.string(forKey: "JamfConnectElevationURL") ?? ""
    }

    // MARK: - Logging

    /// Whether to write a local log file for audit purposes
    var enableLocalAuditLog: Bool {
        let value = defaults.object(forKey: "EnableLocalAuditLog")
        return (value as? Bool) ?? true
    }

    /// Path for the local audit log
    var auditLogPath: String {
        defaults.string(forKey: "AuditLogPath") ?? "/Library/Logs/AdminRightsManager.log"
    }
}
