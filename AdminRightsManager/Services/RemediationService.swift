//
//  RemediationService.swift
//  AdminRightsManager
//
//  Handles the actual remediation: removing the current user
//  from the admin group. This requires elevated privileges,
//  so the service communicates with the privileged helper tool
//  installed as a LaunchDaemon.
//

import Foundation
import os.log

class RemediationService {
    private let logger = Logger(subsystem: AppConfiguration.bundleIdentifier, category: "Remediation")
    private let config = AppConfiguration.shared

    /// Path to the signal file that tells the privileged helper to act
    private let remediationSignalPath = "/Library/Application Support/AdminRightsManager/remediate"

    /// Path where the helper writes its result
    private let remediationResultPath = "/Library/Application Support/AdminRightsManager/result"

    // MARK: - Remediation

    /// Initiates remediation for the current user.
    /// The actual privilege removal is performed by the LaunchDaemon helper
    /// which runs as root. This method signals the helper and waits for completion.
    func remediateCurrentUser(completion: @escaping (Result<String, RemediationError>) -> Void) {
        let currentUser = NSUserName()
        logger.notice("Initiating remediation for user: \(currentUser)")

        // Write audit log entry
        auditLog("User \(currentUser) initiated self-remediation")

        // Signal the privileged helper by writing the username to the signal file
        do {
            let signalDir = (remediationSignalPath as NSString).deletingLastPathComponent
            try FileManager.default.createDirectory(
                atPath: signalDir,
                withIntermediateDirectories: true
            )
            try currentUser.write(
                toFile: remediationSignalPath,
                atomically: true,
                encoding: .utf8
            )
        } catch {
            logger.error("Failed to write remediation signal: \(error.localizedDescription)")
            completion(.failure(.signalFailed(error.localizedDescription)))
            return
        }

        // Poll for the result from the privileged helper
        // The helper watches for the signal file and processes it
        pollForResult(timeout: 30) { result in
            switch result {
            case .success(let message):
                self.auditLog("Remediation completed successfully for \(currentUser): \(message)")
                self.logger.notice("Remediation successful for \(currentUser)")
                completion(.success(message))
            case .failure(let error):
                self.auditLog("Remediation FAILED for \(currentUser): \(error)")
                self.logger.error("Remediation failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    private func pollForResult(timeout: TimeInterval, completion: @escaping (Result<String, RemediationError>) -> Void) {
        let startTime = Date()

        DispatchQueue.global(qos: .userInitiated).async {
            while Date().timeIntervalSince(startTime) < timeout {
                if FileManager.default.fileExists(atPath: self.remediationResultPath) {
                    do {
                        let result = try String(contentsOfFile: self.remediationResultPath, encoding: .utf8)
                        // Clean up
                        try? FileManager.default.removeItem(atPath: self.remediationResultPath)
                        try? FileManager.default.removeItem(atPath: self.remediationSignalPath)

                        if result.hasPrefix("SUCCESS") {
                            DispatchQueue.main.async {
                                completion(.success(result))
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(.failure(.helperReportedFailure(result)))
                            }
                        }
                        return
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(.resultReadFailed(error.localizedDescription)))
                        }
                        return
                    }
                }
                Thread.sleep(forTimeInterval: 0.5)
            }

            DispatchQueue.main.async {
                completion(.failure(.timeout))
            }
        }
    }

    // MARK: - Audit Logging

    private func auditLog(_ message: String) {
        guard config.enableLocalAuditLog else { return }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let entry = "[\(timestamp)] \(message)\n"

        let logPath = config.auditLogPath

        if FileManager.default.fileExists(atPath: logPath) {
            if let handle = FileHandle(forWritingAtPath: logPath) {
                handle.seekToEndOfFile()
                handle.write(entry.data(using: .utf8) ?? Data())
                handle.closeFile()
            }
        } else {
            try? entry.write(toFile: logPath, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - Error Types

    enum RemediationError: LocalizedError {
        case signalFailed(String)
        case timeout
        case helperReportedFailure(String)
        case resultReadFailed(String)
        case helperNotInstalled

        var errorDescription: String? {
            switch self {
            case .signalFailed(let detail):
                return "Could not signal the remediation helper: \(detail)"
            case .timeout:
                return "Remediation timed out. The privileged helper may not be running."
            case .helperReportedFailure(let detail):
                return "The helper reported a failure: \(detail)"
            case .resultReadFailed(let detail):
                return "Could not read the remediation result: \(detail)"
            case .helperNotInstalled:
                return "The privileged helper tool is not installed."
            }
        }
    }
}
