//
//  AdminRightsManagerApp.swift
//  AdminRightsManager
//
//  Admin Rights Management Tool
//  Deployed via Jamf Pro to enforce admin rights policy compliance.
//

import SwiftUI
import os.log

@main
struct AdminRightsManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(width: 750, height: 680)
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: AppConfiguration.bundleIdentifier, category: "AppDelegate")

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("AdminRightsManager launched")

        // Check if the current user actually has admin rights
        // If they don't (already remediated), quit gracefully
        let detector = AdminDetector()
        if !detector.currentUserIsAdmin() {
            logger.info("Current user is not an admin. No action needed. Quitting.")
            NSApplication.shared.terminate(nil)
            return
        }

        logger.notice("Current user has admin rights. Displaying compliance nag.")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// MARK: - App State

class AppState: ObservableObject {
    enum ViewState {
        case nag
        case report
        case remediating
        case remediationComplete
        case error(String)
    }

    @Published var currentView: ViewState = .nag
    @Published var systemReport: SystemReport?
    @Published var isLoading: Bool = false

    let config = AppConfiguration.shared
    let adminDetector = AdminDetector()
    let systemInfoGatherer = SystemInfoGatherer()
    let remediationService = RemediationService()
}
