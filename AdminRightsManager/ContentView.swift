//
//  ContentView.swift
//  AdminRightsManager
//
//  Root view that routes between the nag screen, report view,
//  remediation progress, and completion states.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Background gradient — adapts to light/dark appearance
            LinearGradient(
                gradient: Gradient(colors: [
                    .backgroundTop,
                    .backgroundBottom
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            currentView
                .animation(.easeInOut(duration: 0.3), value: viewIdentifier)
        }
    }

    @ViewBuilder
    private var currentView: some View {
        switch appState.currentView {
        case .nag:
            NagView()
                .transition(.opacity)

        case .report:
            if let report = appState.systemReport {
                ReportView(report: report)
                    .transition(.opacity)
            }

        case .remediating:
            RemediatingView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)

        case .remediationComplete:
            RemediationCompleteView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.scale)

        case .error(let message):
            ErrorView(message: message)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
        }
    }

    // Helper to drive animations on view changes
    private var viewIdentifier: String {
        switch appState.currentView {
        case .nag: return "nag"
        case .report: return "report"
        case .remediating: return "remediating"
        case .remediationComplete: return "complete"
        case .error: return "error"
        }
    }
}

// MARK: - Remediating View (progress spinner)

struct RemediatingView: View {
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(2)
                .tint(.accent)

            Text("Removing Admin Privileges...")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Text("Please wait while your account is updated.\nThis should only take a moment.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - Remediation Complete View

struct RemediationCompleteView: View {
    @State private var copied = false
    @State private var countdown = 30
    @State private var timer: Timer?

    private let config = AppConfiguration.shared
    private let receipt: RemediationReceipt

    init() {
        let gatherer = SystemInfoGatherer()
        self.receipt = RemediationReceipt(
            timestamp: Date(),
            username: NSUserName(),
            fullName: NSFullUserName(),
            hostname: gatherer.hostname(),
            serialNumber: gatherer.serialNumber(),
            macOSVersion: "\(gatherer.macOSProductName()) \(gatherer.macOSVersion())",
            hardwareModel: gatherer.hardwareModel(),
            organization: AppConfiguration.shared.organizationName
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            // Success header
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("Remediation Complete")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text("Your admin privileges have been removed. Your account is now a standard user and compliant with \(config.organizationName) policy.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)

            // Receipt card
            VStack(alignment: .leading, spacing: 0) {
                // Receipt header
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.accent)
                    Text("Remediation Receipt")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Button {
                        copyReceipt()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Copied" : "Copy")
                        }
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondaryButtonBackground)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.cardBackground.opacity(0.6))

                Divider().background(Color.divider)

                // Receipt body
                VStack(alignment: .leading, spacing: 8) {
                    receiptRow(label: "Action", value: "Admin rights removed")
                    receiptRow(label: "Status", value: "Completed successfully", valueColor: .green)
                    Divider().background(Color.divider).padding(.vertical, 4)
                    receiptRow(label: "Date & Time", value: receipt.formattedTimestamp)
                    receiptRow(label: "Username", value: receipt.username)
                    receiptRow(label: "Full Name", value: receipt.fullName)
                    Divider().background(Color.divider).padding(.vertical, 4)
                    receiptRow(label: "Computer", value: receipt.hostname)
                    receiptRow(label: "Serial Number", value: receipt.serialNumber)
                    receiptRow(label: "Model", value: receipt.hardwareModel)
                    receiptRow(label: "macOS", value: receipt.macOSVersion)
                    Divider().background(Color.divider).padding(.vertical, 4)
                    receiptRow(label: "Organization", value: receipt.organization)
                    receiptRow(label: "Reference ID", value: receipt.referenceID)
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.cardBorder, lineWidth: 1)
                    )
            )
            .frame(maxWidth: 500)

            Text("Save or copy this receipt for your records. If you need temporary admin access in the future, contact \(config.supportContactName).")
                .font(.callout)
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)

            // OK button with countdown
            Button {
                signalCleanupAndClose()
            } label: {
                Text(countdown > 0 ? "OK — closing in \(countdown)s" : "OK")
                    .frame(minWidth: 200)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 4)
        }
        .padding(32)
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Receipt Row

    private func receiptRow(label: String, value: String, valueColor: Color = .textPrimary) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundColor(.textTertiary)
                .frame(width: 110, alignment: .trailing)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
                .textSelection(.enabled)
            Spacer()
        }
    }

    // MARK: - Actions

    private func copyReceipt() {
        let text = receipt.formattedText
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }

    private func startCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer?.invalidate()
                signalCleanupAndClose()
            }
        }
    }

    private func signalCleanupAndClose() {
        timer?.invalidate()

        // Write cleanup signal for the privileged helper to uninstall
        let cleanupSignalPath = "/Library/Application Support/AdminRightsManager/cleanup"
        try? "cleanup".write(toFile: cleanupSignalPath, atomically: true, encoding: .utf8)

        // Give the signal a moment to be written, then quit
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApplication.shared.terminate(nil)
        }
    }
}

// MARK: - Remediation Receipt Model

struct RemediationReceipt {
    let timestamp: Date
    let username: String
    let fullName: String
    let hostname: String
    let serialNumber: String
    let macOSVersion: String
    let hardwareModel: String
    let organization: String

    /// Unique reference ID for this remediation event
    var referenceID: String {
        let dateStr = ISO8601DateFormatter().string(from: timestamp)
        let hash = abs("\(username)\(serialNumber)\(dateStr)".hashValue)
        return "REM-\(String(hash).prefix(8))"
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }

    var formattedText: String {
        """
        ═══════════════════════════════════════════════
          ADMIN RIGHTS REMEDIATION RECEIPT
          \(organization)
        ═══════════════════════════════════════════════

          Action:         Admin rights removed
          Status:         Completed successfully
          Date & Time:    \(formattedTimestamp)

          Username:       \(username)
          Full Name:      \(fullName)

          Computer:       \(hostname)
          Serial Number:  \(serialNumber)
          Model:          \(hardwareModel)
          macOS:          \(macOSVersion)

          Organization:   \(organization)
          Reference ID:   \(referenceID)

        ═══════════════════════════════════════════════
          This receipt confirms that administrator
          privileges were voluntarily removed from the
          above account in compliance with organizational
          security policy.
        ═══════════════════════════════════════════════
        """
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Something Went Wrong")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text(message)
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 450)

            HStack(spacing: 16) {
                Button("Try Again") {
                    appState.currentView = .nag
                }
                .buttonStyle(SecondaryButtonStyle())

                if AppConfiguration.shared.hasAnySupportContact {
                    Button("Contact \(AppConfiguration.shared.supportContactName)") {
                        let config = AppConfiguration.shared
                        if !config.supportEmail.isEmpty,
                           let url = URL(string: "mailto:\(config.supportEmail)") {
                            NSWorkspace.shared.open(url)
                        } else if !config.supportWebsiteURL.isEmpty,
                                  let url = URL(string: config.supportWebsiteURL) {
                            NSWorkspace.shared.open(url)
                        } else if !config.supportPhone.isEmpty,
                                  let url = URL(string: "tel:\(config.supportPhone)") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(.top, 8)
        }
        .padding(40)
    }
}

// MARK: - Custom Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accent)
                    .opacity(configuration.isPressed ? 0.7 : 1.0)
            )
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.secondaryButtonText)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondaryButtonBorder, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondaryButtonBackground.opacity(configuration.isPressed ? 0.8 : 1.0))
                    )
            )
    }
}

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accent)
                    .opacity(configuration.isPressed ? 0.7 : 1.0)
            )
    }
}
