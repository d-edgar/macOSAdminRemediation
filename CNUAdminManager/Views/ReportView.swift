//
//  ReportView.swift
//  CNUAdminManager
//
//  Displays the diagnostic system report after the user clicks
//  "Submit Request". The report is formatted for easy copy/paste
//  into a service request ticket. Also includes a screenshot-ready
//  layout and a "Copy to Clipboard" button.
//

import SwiftUI

struct ReportView: View {
    @EnvironmentObject var appState: AppState
    @State private var copied = false
    @State private var screenshotSaved = false

    private let config = AppConfiguration.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            if let report = appState.systemReport {
                ScrollView {
                    VStack(spacing: 20) {
                        instructions
                        reportCard(report)
                        actionButtons(report)
                        backButton
                    }
                    .padding(28)
                }
            } else {
                Spacer()
                ProgressView("Generating report...")
                    .foregroundColor(.white)
                Spacer()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                appState.currentView = .nag
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Elevation Request Report")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            // Spacer for symmetry
            Color.clear.frame(width: 60)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color(red: 0.12, green: 0.12, blue: 0.18))
    }

    // MARK: - Instructions

    private var instructions: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .font(.title3)

            VStack(alignment: .leading, spacing: 6) {
                Text("How to submit your request")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text("Copy the report below and paste it into your admin rights request. You can also take a screenshot of this window. Submit your request at:")
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(2)

                if let url = URL(string: config.supportRequestURL) {
                    Link(config.supportRequestURL, destination: url)
                        .font(.callout)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Report Card

    private func reportCard(_ report: SystemReport) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Report title bar
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.green)
                Text("System Diagnostic Report")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
                Text(report.generatedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.05))

            Divider().background(Color.white.opacity(0.1))

            // Device Info Section
            reportSection("Device Information") {
                reportRow("Hostname", report.hostname)
                reportRow("Serial Number", report.serialNumber)
                reportRow("Hardware", report.hardwareModel)
                reportRow("macOS", "\(report.macOSVersion) (\(report.macOSBuild))")
                reportRow("Jamf Pro", report.jamfProEnrolled ? "Enrolled" : "Not Detected")
            }

            Divider().background(Color.white.opacity(0.1))

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
                            .foregroundColor(.orange.opacity(0.8))
                    }
                    .padding(.top, 4)
                }
            }

            Divider().background(Color.white.opacity(0.1))

            // Admin Users Section
            reportSection("Admin Users on This Device") {
                ForEach(report.adminUsers) { user in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(user.username)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)

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
                                .foregroundColor(.white.opacity(0.6))

                            Label(user.accountType.rawValue, systemImage: "key.fill")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func reportSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.4))
                .tracking(1)

            content()
        }
        .padding(16)
    }

    private func reportRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.callout)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.white)

            Spacer()
        }
    }

    // MARK: - Action Buttons

    private func actionButtons(_ report: SystemReport) -> some View {
        HStack(spacing: 14) {
            // Copy report to clipboard
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(report.formattedReport, forType: .string)
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    copied = false
                }
            } label: {
                HStack {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    Text(copied ? "Copied!" : "Copy Report to Clipboard")
                }
            }
            .buttonStyle(CNUPrimaryButtonStyle())

            // Open support request URL
            Button {
                if let url = URL(string: config.supportRequestURL) {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "globe")
                    Text("Open Request Portal")
                }
            }
            .buttonStyle(CNUSecondaryButtonStyle())
        }
    }

    // MARK: - Back Button

    private var backButton: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color.white.opacity(0.1))

            Button {
                appState.currentView = .nag
            } label: {
                Text("Go Back")
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
    }
}
