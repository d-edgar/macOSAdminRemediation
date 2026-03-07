//
//  ContentView.swift
//  CNUAdminManager
//
//  Root view that routes between the nag screen, report view,
//  remediation progress, and completion states.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.10, blue: 0.20),
                    Color(red: 0.08, green: 0.15, blue: 0.28)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                switch appState.currentView {
                case .nag:
                    NagView()
                        .transition(.opacity)

                case .report:
                    ReportView()
                        .transition(.move(edge: .trailing))

                case .remediating:
                    RemediatingView()
                        .transition(.opacity)

                case .remediationComplete:
                    RemediationCompleteView()
                        .transition(.scale)

                case .error(let message):
                    ErrorView(message: message)
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

            Text("Your admin privileges have been removed.\nYour account is now a standard user and compliant with CNU policy.")
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
            .buttonStyle(CNUPrimaryButtonStyle())
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
                .buttonStyle(CNUSecondaryButtonStyle())

                Button("Contact IT Support") {
                    if let url = URL(string: "mailto:\(AppConfiguration.shared.supportEmail)") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(CNUPrimaryButtonStyle())
            }
            .padding(.top, 8)
        }
        .padding(40)
    }
}

// MARK: - Custom Button Styles

struct CNUPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue)
                    .opacity(configuration.isPressed ? 0.7 : 1.0)
            )
    }
}

struct CNUSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(configuration.isPressed ? 0.15 : 0.08))
                    )
            )
    }
}

struct CNUDangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.red)
                    .opacity(configuration.isPressed ? 0.7 : 1.0)
            )
    }
}
