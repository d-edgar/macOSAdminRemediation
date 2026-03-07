//
//  SystemReport.swift
//  AdminRightsManager
//
//  Data model for the diagnostic report generated when a user
//  clicks "Submit Request". Contains all information needed for
//  the IT team to process an elevation request.
//

import Foundation

struct AdminUserInfo: Identifiable {
    let id = UUID()
    let username: String
    let fullName: String
    let isCurrentUser: Bool
    let accountType: AccountType

    /// User ID (UID) for local accounts (e.g., 502, 503)
    let uid: String?

    enum AccountType: String, CustomStringConvertible {
        case local = "Local Account"
        case mobile = "Mobile Account (Domain-bound)"
        case network = "Network Account"
        case unknown = "Unknown"

        var description: String { rawValue }

        /// Short explanation shown in the report UI
        var explanation: String {
            switch self {
            case .local: return "Local account with a local UID"
            case .mobile: return "Device is bound to a directory; cached domain credentials"
            case .network: return "Authenticated against network directory"
            case .unknown: return "Could not determine account type"
            }
        }
    }
}

struct SystemReport: Identifiable {
    let id = UUID()
    let generatedAt: Date
    let hostname: String
    let serialNumber: String
    let macOSVersion: String
    let macOSBuild: String
    let currentUser: String
    let adminUsers: [AdminUserInfo]
    let jamfConnectInstalled: Bool
    let jamfConnectVersion: String?
    let jamfProEnrolled: Bool
    let hardwareModel: String

    // MARK: - Formatted Output

    /// Plain-text report suitable for copy/paste into a ticket
    var formattedReport: String {
        let divider = String(repeating: "─", count: 56)
        let timestamp = ISO8601DateFormatter().string(from: generatedAt)

        var lines: [String] = []

        lines.append("╔══════════════════════════════════════════════════════════╗")
        lines.append("║       Admin Rights — Elevation Request Report       ║")
        lines.append("╚══════════════════════════════════════════════════════════╝")
        lines.append("")
        lines.append("Generated: \(timestamp)")
        lines.append("")
        lines.append(divider)
        lines.append(" DEVICE INFORMATION")
        lines.append(divider)
        lines.append("  Hostname:        \(hostname)")
        lines.append("  Serial Number:   \(serialNumber)")
        lines.append("  Hardware Model:  \(hardwareModel)")
        lines.append("  macOS Version:   \(macOSVersion) (\(macOSBuild))")
        lines.append("  Jamf Pro:        \(jamfProEnrolled ? "Enrolled" : "Not Detected")")
        lines.append("")
        lines.append(divider)
        lines.append(" JAMF CONNECT STATUS")
        lines.append(divider)
        lines.append("  Installed:       \(jamfConnectInstalled ? "Yes" : "No")")

        if let version = jamfConnectVersion {
            lines.append("  Version:         \(version)")
        }

        lines.append("")
        lines.append(divider)
        lines.append(" CURRENT USER")
        lines.append(divider)
        lines.append("  Username:        \(currentUser)")

        if let currentUserInfo = adminUsers.first(where: { $0.isCurrentUser }) {
            lines.append("  Account Type:    \(currentUserInfo.accountType)")
            lines.append("  Admin Status:    Yes (requires remediation)")
        }

        lines.append("")
        lines.append(divider)
        lines.append(" ALL ADMIN USERS ON THIS DEVICE")
        lines.append(divider)

        for (index, user) in adminUsers.enumerated() {
            let marker = user.isCurrentUser ? " ← (current user)" : ""
            lines.append("")
            lines.append("  \(index + 1). \(user.username)\(marker)")
            lines.append("     Full Name:    \(user.fullName)")
            lines.append("     Account Type: \(user.accountType)")
            if let uid = user.uid {
                lines.append("     UID:          \(uid)")
            }
        }

        lines.append("")
        lines.append(divider)
        lines.append(" ACTION REQUESTED")
        lines.append(divider)
        lines.append("  The above user is requesting to maintain or obtain")
        lines.append("  administrator privileges on this device. Please review")
        lines.append("  and process per admin rights policy.")
        lines.append("")
        lines.append("══════════════════════════════════════════════════════════")

        return lines.joined(separator: "\n")
    }
}
