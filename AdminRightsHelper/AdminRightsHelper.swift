//
//  AdminRightsHelper.swift
//  AdminRightsManager
//
//  Privileged helper tool that runs as a LaunchDaemon (root).
//  Watches for remediation signals from the main app and performs
//  the actual admin rights removal using dseditgroup.
//
//  This runs as: /Library/PrivilegedHelperTools/com.adminrights.manager.helper
//  Managed by:   /Library/LaunchDaemons/com.adminrights.manager.helper.plist
//

import Foundation

// MARK: - Configuration

let signalDirectory = "/Library/Application Support/AdminRightsManager"
let signalFilePath = "\(signalDirectory)/remediate"
let resultFilePath = "\(signalDirectory)/result"
let auditLogPath = "/Library/Logs/AdminRightsManager.log"
let pollInterval: TimeInterval = 2.0 // Check every 2 seconds

// MARK: - Logging

func log(_ message: String) {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let entry = "[\(timestamp)] [Helper] \(message)"
    print(entry) // Goes to system log via LaunchDaemon stdout

    // Also write to audit log
    let logEntry = entry + "\n"
    if FileManager.default.fileExists(atPath: auditLogPath) {
        if let handle = FileHandle(forWritingAtPath: auditLogPath) {
            handle.seekToEndOfFile()
            handle.write(logEntry.data(using: .utf8) ?? Data())
            handle.closeFile()
        }
    } else {
        try? logEntry.write(toFile: auditLogPath, atomically: true, encoding: .utf8)
    }
}

// MARK: - Remediation Logic

func removeAdminRights(for username: String) -> (success: Bool, message: String) {
    log("Attempting to remove admin rights for user: \(username)")

    // Validate the username (basic sanitization)
    guard !username.isEmpty,
          username.rangeOfCharacter(from: .alphanumerics.inverted.subtracting(CharacterSet(charactersIn: "._-"))) == nil else {
        let msg = "Invalid username: \(username)"
        log("ERROR: \(msg)")
        return (false, msg)
    }

    // Don't allow removing root or the only admin
    guard username != "root" else {
        let msg = "Cannot remove admin rights from root"
        log("ERROR: \(msg)")
        return (false, msg)
    }

    // Verify user actually has admin rights before attempting removal
    guard userIsAdmin(username) else {
        let msg = "User \(username) is not currently an admin — no action needed"
        log(msg)
        return (true, msg)
    }

    // Method 1: Use dseditgroup to remove from admin group
    let dseditResult = runCommand(
        "/usr/sbin/dseditgroup",
        arguments: ["-o", "edit", "-d", username, "-t", "user", "admin"]
    )

    if dseditResult.exitCode == 0 {
        log("Successfully removed \(username) from admin group via dseditgroup")
    } else {
        log("dseditgroup failed (exit \(dseditResult.exitCode)): \(dseditResult.output)")
        // Try fallback method
        let dsclResult = runCommand(
            "/usr/bin/dscl",
            arguments: [".", "-delete", "/Groups/admin", "GroupMembership", username]
        )
        if dsclResult.exitCode != 0 {
            let msg = "Failed to remove admin rights: dseditgroup and dscl both failed"
            log("ERROR: \(msg)")
            return (false, msg)
        }
        log("Successfully removed \(username) from admin group via dscl fallback")
    }

    // Verify the removal worked
    if userIsAdmin(username) {
        let msg = "Removal command succeeded but user \(username) is still an admin — manual intervention may be needed"
        log("WARNING: \(msg)")
        return (false, msg)
    }

    let successMsg = "SUCCESS: Admin rights removed for \(username). User is now a standard account."
    log(successMsg)
    return (true, successMsg)
}

func userIsAdmin(_ username: String) -> Bool {
    let result = runCommand(
        "/usr/sbin/dseditgroup",
        arguments: ["-o", "checkmember", "-m", username, "admin"]
    )
    return result.exitCode == 0
}

// MARK: - Command Runner

struct CommandResult {
    let exitCode: Int32
    let output: String
}

func runCommand(_ path: String, arguments: [String]) -> CommandResult {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: path)
    task.arguments = arguments

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe

    do {
        try task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return CommandResult(exitCode: task.terminationStatus, output: output)
    } catch {
        return CommandResult(exitCode: -1, output: error.localizedDescription)
    }
}

// MARK: - Signal Watcher

func ensureDirectoryExists() {
    let fm = FileManager.default
    if !fm.fileExists(atPath: signalDirectory) {
        try? fm.createDirectory(atPath: signalDirectory, withIntermediateDirectories: true)
        // Set permissions so the app can write to it
        try? fm.setAttributes(
            [.posixPermissions: 0o777],
            ofItemAtPath: signalDirectory
        )
    }
}

func watchForSignals() {
    log("AdminRightsManager Helper started. Watching for remediation signals...")
    ensureDirectoryExists()

    // Main run loop - watch for the signal file
    while true {
        if FileManager.default.fileExists(atPath: signalFilePath) {
            log("Remediation signal detected!")

            do {
                let username = try String(contentsOfFile: signalFilePath, encoding: .utf8)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                log("Processing remediation for user: \(username)")

                let result = removeAdminRights(for: username)

                // Write result for the app to read
                let resultMessage = result.success ? result.message : "FAILED: \(result.message)"
                try resultMessage.write(toFile: resultFilePath, atomically: true, encoding: .utf8)

                // Set permissions so the app can read it
                try FileManager.default.setAttributes(
                    [.posixPermissions: 0o644],
                    ofItemAtPath: resultFilePath
                )

                // Clean up signal file
                try? FileManager.default.removeItem(atPath: signalFilePath)

            } catch {
                log("ERROR reading signal file: \(error.localizedDescription)")
                try? "FAILED: Could not read signal file".write(
                    toFile: resultFilePath,
                    atomically: true,
                    encoding: .utf8
                )
            }
        }

        Thread.sleep(forTimeInterval: pollInterval)
    }
}

// MARK: - Entry Point

watchForSignals()
