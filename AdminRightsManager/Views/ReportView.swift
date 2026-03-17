//
//  ReportView.swift
//  AdminRightsManager
//
//  Displays the diagnostic system report after the user clicks
//  "Submit Request". The report is formatted for easy copy/paste
//  into a service request ticket. Also includes a screenshot-ready
//  layout and a "Copy to Clipboard" button.
//

import SwiftUI

struct ReportView: View {
    @EnvironmentObject var appState: AppState
    let report: SystemReport
    @State private var copied = false
    @State private var hasCopied = false

    private let config = AppConfiguration.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                instructions
                reportCard
                actionButtons
                backButton
            }
            .padding(28)
        }
    }

    // MARK: - Instructions

    private var instructions: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.accent)
                .font(.title3)

            VStack(alignment: .leading, spacing: 6) {
                Text("How to submit your request")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)

                if !config.supportRequestURL.isEmpty, let url = URL(string: config.supportRequestURL) {
                    Text("Copy the report below and paste it into your admin rights request. You can also take a screenshot of this window. Submit your request at:")
                        .font(.callout)
                        .foregroundColor(.textSecondary)
                        .lineSpacing(2)

                    Link(config.supportRequestURL, destination: url)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.accent)
                } else {
                    Text("Copy the report below and paste it into your admin rights request. You can also take a screenshot of this window.")
                        .font(.callout)
                        .foregroundColor(.textSecondary)
                        .lineSpacing(2)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.infoBoxBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.infoBoxBorder, lineWidth: 1)
                )
        )
    }

    // MARK: - Report Card

    private var reportCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Report title bar
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.green)
                Text("System Diagnostic Report")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text(report.generatedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.cardBackground.opacity(0.6))

            Divider().background(Color.divider)

            // Device Info Section
            reportSection("Device Information") {
                reportRow("Hostname", report.hostname)
                reportRow("Serial Number", report.serialNumber)
                reportRow("Hardware", report.hardwareModel)
                reportRow("macOS", "\(report.macOSVersion) (\(report.macOSBuild))")
                reportRow("Jamf Pro", report.jamfProEnrolled ? "Enrolled" : "Not Detected")
            }

            Divider().background(Color.divider)

            // Jamf Connect Section
            reportSection("Jamf Connect") {
                reportRow("Installed", report.jamfConnectInstalled ? "Yes" : "No")
                if let version = report.jamfConnectVersion {
                    reportRow("Version", version)
                }
                if !report.jamfConnectInstalled {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("Jamf Connect is not installed — temporary elevation may not be available")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 4)
                }
            }

            Divider().background(Color.divider)

            // Admin Users Section
            reportSection("Admin Users on This Device") {
                ForEach(report.adminUsers) { user in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(user.username)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)

                            if user.isCurrentUser {
                                Text("(you)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color.orange.opacity(0.2))
                                    )
                            }
                        }

                        HStack(spacing: 16) {
                            Label(user.fullName, systemImage: "person.fill")
                                .font(.caption)
                                .foregroundColor(.textSecondary)

                            Label(user.accountType.rawValue, systemImage: user.accountType == .mobile ? "network" : "desktopcomputer")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(user.accountType == .mobile ? .orange : .textSecondary)

                            if let uid = user.uid {
                                Label("UID \(uid)", systemImage: "number")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cardBorder, lineWidth: 1)
                )
        )
    }

    private func reportSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.textTertiary)
                .tracking(1)

            content()
        }
        .padding(16)
    }

    private func reportRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.callout)
                .foregroundColor(.textSecondary)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)

            Spacer()
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Step 1: Copy report to clipboard
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(report.formattedReport, forType: .string)
                    copied = true
                    hasCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                } label: {
                    HStack {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copied!" : "Step 1: Copy Report to Clipboard")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                // Step 2: Open support request URL (only enabled after copy, closes app)
                if !config.supportRequestURL.isEmpty {
                    Button {
                        if let url = URL(string: config.supportRequestURL) {
                            NSWorkspace.shared.open(url)
                        }
                        // Hide the window first so the quit guard allows termination,
                        // then close the app after opening the portal
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            NSApplication.shared.windows.first?.orderOut(nil)
                            NSApplication.shared.terminate(nil)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                            Text("Step 2: Open Help Desk Portal")
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(!hasCopied)
                    .opacity(hasCopied ? 1.0 : 0.4)
                }
            }

            // Hint text when portal is locked
            if !hasCopied && !config.supportRequestURL.isEmpty {
                Text("Copy the report first, then open the portal to paste it into your request.")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                    .italic()
            }
        }
    }

    // MARK: - Back Button

    private var backButton: some View {
        VStack(spacing: 12) {
            Divider()
                .background(Color.divider)

            Button {
                appState.currentView = .nag
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Go Back")
                }
                .font(.callout)
                .foregroundColor(.textSecondary)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)
        }
    }
}
