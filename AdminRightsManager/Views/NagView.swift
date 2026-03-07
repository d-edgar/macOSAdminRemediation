//
//  NagView.swift
//  AdminRightsManager
//
//  The main nag screen displayed to users who have admin rights.
//  Shows a policy warning and presents two options:
//  1. Remediate (remove admin rights now)
//  2. Submit Request (generate a report to request elevation)
//

import SwiftUI

struct NagView: View {
    @EnvironmentObject var appState: AppState
    @State private var showRemediateConfirmation = false
    @State private var pulseWarning = false

    private let config = AppConfiguration.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header banner
            headerBanner

            // Main content
            ScrollView {
                VStack(spacing: 28) {
                    warningIcon
                    policyMessage
                    actionButtons
                    supportInfo
                }
                .padding(32)
            }
        }
        .alert("Confirm Remediation", isPresented: $showRemediateConfirmation) {
            Button("Remove Admin Rights", role: .destructive) {
                performRemediation()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove administrator privileges from your account. You will become a standard user. If you need admin access later, you can request temporary elevation through Jamf Connect.\n\nThis action takes effect immediately.")
        }
    }

    // MARK: - Header Title

    /// Combines org name and department name, avoiding duplication
    /// when both are set to the same value.
    private var headerTitle: String {
        let org = config.organizationName
        let dept = config.departmentName
        if org.lowercased() == dept.lowercased() || dept.isEmpty {
            return org
        }
        return "\(org) \(dept)"
    }

    // MARK: - Header

    private var headerBanner: some View {
        HStack {
            // Custom logo from config profile, or fallback SF Symbol
            if let logoImage = loadLogoImage() {
                Image(nsImage: logoImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
            } else {
                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .font(.title2)
                    .foregroundColor(.white)
            }

            Text(headerTitle)
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            if !config.policyURL.isEmpty, let url = URL(string: config.policyURL) {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Text("Admin Rights Policy")
                            .font(.subheadline)
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            } else {
                Text("Admin Rights Policy")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color.headerBar)
    }

    // MARK: - Warning Icon

    private var warningIcon: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulseWarning ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: pulseWarning
                    )

                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
            }
            .onAppear { pulseWarning = true }

            Text("Action Required")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Your account has admin privileges that are not in compliance")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
    }

    // MARK: - Policy Message

    private var policyMessage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(config.policyMessage)
                .font(.body)
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(4)

            // Info box
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.brandPrimary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text("What happens next?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text("This reminder will appear \(config.nagIntervalDescription) until resolved. You can either remove your admin rights now, or submit a request if you need to retain them for a valid business reason.")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.7))
                        .lineSpacing(2)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.brandPrimary.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.brandPrimary.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .frame(maxWidth: 520)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 14) {
            // Primary action: Remediate
            Button {
                showRemediateConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "shield.checkered")
                    Text("Remediate — Remove My Admin Rights")
                    Spacer()
                    Image(systemName: "arrow.right.circle")
                }
                .frame(maxWidth: 480)
            }
            .buttonStyle(DangerButtonStyle())

            // Secondary action: Submit Request
            if config.showSubmitRequestOption {
                Button {
                    generateAndShowReport()
                } label: {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("Submit Request — I Need Admin Access")
                        Spacer()
                        if appState.isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.right.circle")
                        }
                    }
                    .frame(maxWidth: 480)
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(appState.isLoading)
            }
        }
    }

    // MARK: - Support Info

    private var supportInfo: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.bottom, 4)

            Text("Need help? Contact \(config.supportContactName)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.5))

            // Contact methods — only show configured ones
            HStack(spacing: 16) {
                if !config.supportPhone.isEmpty {
                    Link(destination: URL(string: "tel:\(config.supportPhone)")!) {
                        Label(config.supportPhone, systemImage: "phone.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                if !config.supportEmail.isEmpty {
                    Link(destination: URL(string: "mailto:\(config.supportEmail)")!) {
                        Label(config.supportEmail, systemImage: "envelope.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                if !config.supportWebsiteURL.isEmpty {
                    if let url = URL(string: config.supportWebsiteURL) {
                        Link(destination: url) {
                            Label("Website", systemImage: "globe")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
            }

            Text("This tool is managed by \(headerTitle)")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.3))
        }
    }

    // MARK: - Logo Loader

    /// Loads a custom logo from the path specified in the config profile.
    /// Returns nil if no path is set or the file doesn't exist.
    private func loadLogoImage() -> NSImage? {
        let path = config.logoImagePath
        guard !path.isEmpty else { return nil }
        return NSImage(contentsOfFile: path)
    }

    // MARK: - Actions

    private func performRemediation() {
        appState.currentView = .remediating

        appState.remediationService.remediateCurrentUser { result in
            switch result {
            case .success:
                appState.currentView = .remediationComplete
            case .failure(let error):
                appState.currentView = .error(error.localizedDescription)
            }
        }
    }

    private func generateAndShowReport() {
        appState.isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            let adminUsers = appState.adminDetector.getAllAdminUsers()
            let report = appState.systemInfoGatherer.generateReport(adminUsers: adminUsers)

            DispatchQueue.main.async {
                appState.systemReport = report
                appState.isLoading = false
                appState.currentView = .report
            }
        }
    }
}
