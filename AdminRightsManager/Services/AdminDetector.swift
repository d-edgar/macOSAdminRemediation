//
//  AdminDetector.swift
//  AdminRightsManager
//
//  Detects admin users on the system by querying the local
//  directory service. Identifies account types (local, mobile, network)
//  and checks admin group membership.
//

import Foundation
import OpenDirectory
import os.log

class AdminDetector {
    private let logger = Logger(subsystem: AppConfiguration.bundleIdentifier, category: "AdminDetector")

    // MARK: - Current User Check

    /// Quick check: is the currently logged-in user an admin?
    func currentUserIsAdmin() -> Bool {
        let currentUser = NSUserName()
        return isUserAdmin(username: currentUser)
    }

    /// Check if a specific user is in the admin group
    func isUserAdmin(username: String) -> Bool {
        // Method 1: Check admin group membership via dseditgroup
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/dseditgroup")
        task.arguments = ["-o", "checkmember", "-m", username, "admin"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            logger.error("Failed to check admin membership for \(username): \(error.localizedDescription)")
            // Fallback: check via groups command
            return isUserAdminFallback(username: username)
        }
    }

    private func isUserAdminFallback(username: String) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/groups")
        task.arguments = [username]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return output.contains("admin")
        } catch {
            logger.error("Fallback admin check also failed for \(username)")
            return false
        }
    }

    // MARK: - All Admin Users

    /// Get all users who are members of the admin group
    func getAllAdminUsers() -> [AdminUserInfo] {
        var adminUsers: [AdminUserInfo] = []
        let currentUser = NSUserName()

        // Get members of the admin group via dscl
        let members = getAdminGroupMembers()

        for username in members {
            // Skip system accounts
            guard !isSystemAccount(username) else { continue }

            let fullName = getFullName(for: username)
            let accountType = detectAccountType(for: username)

            let userInfo = AdminUserInfo(
                username: username,
                fullName: fullName,
                isCurrentUser: username == currentUser,
                accountType: accountType
            )
            adminUsers.append(userInfo)
        }

        logger.info("Found \(adminUsers.count) admin users on this device")
        return adminUsers
    }

    // MARK: - Admin Group Members

    private func getAdminGroupMembers() -> [String] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/dscl")
        task.arguments = [".", "-read", "/Groups/admin", "GroupMembership"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            // Output format: "GroupMembership: user1 user2 user3"
            let members = output
                .replacingOccurrences(of: "GroupMembership:", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }

            return members
        } catch {
            logger.error("Failed to read admin group members: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Account Type Detection

    /// Determines if an account is local, mobile (AD-bound cached), or network
    func detectAccountType(for username: String) -> AdminUserInfo.AccountType {
        // Check for mobile account by looking at OriginalAuthenticationAuthority
        // or the AuthenticationAuthority attribute
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/dscl")
        task.arguments = [".", "-read", "/Users/\(username)", "AuthenticationAuthority"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe() // Suppress errors for users without this attribute

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if output.contains("LocalCachedUser") {
                return .mobile
            } else if output.contains("NetLogon") || output.contains("Kerberos") {
                return .network
            } else if output.contains("ShadowHash") || output.contains("SecureToken") {
                return .local
            }
        } catch {
            logger.warning("Could not determine account type for \(username)")
        }

        return .unknown
    }

    // MARK: - User Info Helpers

    private func getFullName(for username: String) -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/dscl")
        task.arguments = [".", "-read", "/Users/\(username)", "RealName"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            // Output format: "RealName:\n Full Name"
            let lines = output.components(separatedBy: "\n")
            if lines.count > 1 {
                return lines[1].trimmingCharacters(in: .whitespaces)
            }
        } catch {
            // Ignore
        }

        return username // Fallback to username
    }

    private func isSystemAccount(_ username: String) -> Bool {
        let systemAccounts = ["root", "daemon", "_", "nobody", "Guest"]
        return systemAccounts.contains(username) || username.hasPrefix("_")
    }
}
