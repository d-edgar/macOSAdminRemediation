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
            // Background gradient — brand colors from config profile
            LinearGradient(
                gradient: Gradient(colors: [
                    .backgroundTop,
                    .backgroundBottom
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Group {
                switch appState.currentView {
                case .nag:
                    NagView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .transition(.opacity)

                case .report:
                    ReportView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .transition(.move(edge: .trailing))

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
            .animation(.easeInOut(duration: 0.3), value: viewIdentifier)
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
                .tint(.white)

            Text("Removing Admin Privileges...")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("Please wait while your account is updated.\nThis should only take a moment.")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - Remediation Complete View

struct RemediationCompleteView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("Remediation Complete")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Your admin privileges have been removed.\nYour account is now a standard user and compliant with \(AppConfiguration.shared.organizationName) policy.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 450)

            Text("If you need temporary admin access in the future,\nplease use Jamf Connect or contact IT support.")
                .font(.callout)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 450)

            Button("Close") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 8)
        }
        .padding(40)
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
                .foregroundColor(.white)

            Text(message)
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
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
                    .fill(Color.brandPrimary)
                    .opacity(configuration.isPressed ? 0.7 : 1.0)
            )
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.brandSecondary.opacity(0.4), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.brandSecondary.opacity(configuration.isPressed ? 0.2 : 0.1))
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
                    .fill(Color.brandPrimary)
                    .opacity(configuration.isPressed ? 0.7 : 1.0)
            )
    }
}
