//
//  SystemInfoGatherer.swift
//  CNUAdminManager
//
//  Gathers system-level information for the diagnostic report:
//  macOS version, hardware, Jamf Connect status, enrollment, etc.
//

import Foundation
import IOKit
import os.log

class SystemInfoGatherer {
    private let logger = Logger(subsystem: AppConfiguration.bundleIdentifier, category: "SystemInfo")

    // MARK: - macOS Version

    /// Returns the macOS version string (e.g., "15.3.1")
    func macOSVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    /// Returns the macOS build number (e.g., "24D70")
    func macOSBuild() -> String {
        return runCommand("/usr/bin/sw_vers", arguments: ["-buildVersion"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns the friendly macOS name (e.g., "macOS Sequoia")
    func macOSProductName() -> String {
        return runCommand("/usr/bin/sw_vers", arguments: ["-productName"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Hardware Info

    /// Returns the hostname
    func hostname() -> String {
        return Host.current().localizedName ?? ProcessInfo.processInfo.hostName
    }

    /// Returns the hardware serial number
    func serialNumber() -> String {
        let platformExpert = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )

        guard platformExpert != 0 else {
            logger.warning("Could not get IOPlatformExpertDevice")
            return "Unknown"
        }

        defer { IOObjectRelease(platformExpert) }

        if let serialRef = IORegistryEntryCreateCFProperty(
            platformExpert,
            "IOPlatformSerialNumber" as CFString,
            kCFAllocatorDefault,
            0
        ) {
            return (serialRef.takeRetainedValue() as? String) ?? "Unknown"
        }

        return "Unknown"
    }

    /// Returns the hardware model identifier (e.g., "MacBookPro18,1")
    func hardwareModel() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }

    // MARK: - Jamf Connect Detection

    /// Checks if Jamf Connect is installed
    func isJamfConnectInstalled() -> Bool {
        let config = AppConfiguration.shared
        let appPath = config.jamfConnectAppPath
        return FileManager.default.fileExists(atPath: appPath)
    }

    /// Gets the Jamf Connect version if installed
    func jamfConnectVersion() -> String? {
        let config = AppConfiguration.shared
        let plistPath = "\(config.jamfConnectAppPath)/Contents/Info.plist"

        guard FileManager.default.fileExists(atPath: plistPath),
              let plist = NSDictionary(contentsOfFile: plistPath),
              let version = plist["CFBundleShortVersionString"] as? String else {
            return nil
        }

        return version
    }

    // MARK: - Jamf Pro Enrollment

    /// Checks if the device is enrolled in Jamf Pro
    func isJamfProEnrolled() -> Bool {
        // Check for Jamf binary
        let jamfBinaryExists = FileManager.default.fileExists(atPath: "/usr/local/bin/jamf")
            || FileManager.default.fileExists(atPath: "/usr/local/jamf/bin/jamf")

        // Check for MDM enrollment profile
        let mdmProfileExists = checkMDMEnrollment()

        return jamfBinaryExists || mdmProfileExists
    }

    private func checkMDMEnrollment() -> Bool {
        let output = runCommand("/usr/bin/profiles", arguments: ["status", "-type", "enrollment"])
        return output.contains("MDM enrollment: Yes") || output.contains("Enrolled via DEP: Yes")
    }

    // MARK: - Generate Full Report

    /// Generates a complete SystemReport with all gathered information
    func generateReport(adminUsers: [AdminUserInfo]) -> SystemReport {
        logger.info("Generating system report...")

        let report = SystemReport(
            generatedAt: Date(),
            hostname: hostname(),
            serialNumber: serialNumber(),
            macOSVersion: "\(macOSProductName()) \(macOSVersion())",
            macOSBuild: macOSBuild(),
            currentUser: NSUserName(),
            adminUsers: adminUsers,
            jamfConnectInstalled: isJamfConnectInstalled(),
            jamfConnectVersion: jamfConnectVersion(),
            jamfProEnrolled: isJamfProEnrolled(),
            hardwareModel: hardwareModel()
        )

        logger.info("System report generated successfully")
        return report
    }

    // MARK: - Shell Command Helper

    private func runCommand(_ path: String, arguments: [String] = []) -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            logger.error("Command failed: \(path) \(arguments.joined(separator: " "))")
            return ""
        }
    }
}
