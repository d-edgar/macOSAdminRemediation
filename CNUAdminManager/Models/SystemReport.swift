//
//  SystemReport.swift
//  CNUAdminManager
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

    enum AccountType: String, CustomStringConvertible {
        case local = "Local"
        case mobile = "Mobile (AD-bound)"
        case network = "Network"
        case unknown = "Unknown"

        var description: String { rawValue }
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

        var report = """
        ╔══════════════════════════════════════════════════════════╗
        ║       CNU Admin Rights — Elevation Request Report       ║
        ╚══════════════════════════════════════════════════════════╝

        Generated: \(timestamp)

        \(divider)
         DEVICE INFORMATION
        \(divider)
          Hostname:        \(hostname)
          Serial Number:   \(serialNumber)
          Hardware Model:  \(hardwareModel)
          macOS Version:   \(macOSVersion) (\(macOSBuild))
          Jamf Pro:        \(jamfProEnrolled ? "Enrolled" : "Not Detected")

        \(divider)
         JAMF CONNECT STATUS
        \(divider)
          Installed:       \(jamfConnectInstalled ? "Yes" : "No")
        """

        if let version = jamfConnectVersion {
            report += "\n  Version:         \(version)"
        }

        report += """

        \n\(divider)
         CURRENT USER
        \(divider)
          Username:        \(currentUser)
        """

        if let currentUserInfo = adminUsers.first(where: { $0.isCurrentUser }) {
            report += """

              Account Type:    \(currentUserInfo.accountType)
              Admin Status:    Yes (requires remediation)
            """
        }

        report += """

        \n\(divider)
         ALL ADMIN USERS ON THIS DEVICE
        \(divider)
        """

        for (index, user) in adminUsers.enumerated() {
            report += """

          \(index + 1). \(user.username)\(user.isCurrentUser ? " ← (current user)" : "")
             Full Name:    \(user.fullName)
             Account Type: \(user.accountType)
            """
        }

        report += """

        \n\(divider)
         ACTION REQUESTED
        \(divider)
          The above user is requesting to maintain or obtain
          administrator privileges on this device. Please review
          and process per CNU admin rights policy.

        ══════════════════════════════════════════════════════════
        """

        return report
    }
}
