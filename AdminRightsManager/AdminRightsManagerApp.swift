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
                .frame(width: 750, height: 760)
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    appDelegate.configureMainWindow()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // Remove the standard Close (Cmd+W) and Quit (Cmd+Q) menu items
            // when deferral is not allowed, preventing keyboard dismissal.
            if !AppConfiguration.shared.allowDeferral {
                CommandGroup(replacing: .appTermination) { }
                CommandGroup(replacing: .windowList) { }
            }
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let logger = Logger(subsystem: AppConfiguration.bundleIdentifier, category: "AppDelegate")
    private let config = AppConfiguration.shared

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

    /// Called from ContentView.onAppear once the window exists.
    /// Configures the window as persistent and always-on-top when deferral is disabled.
    func configureMainWindow() {
        guard let window = NSApplication.shared.windows.first else { return }

        window.delegate = self

        if !config.allowDeferral {
            // Float above everything — same level as screen saver
            window.level = .floating

            // Remove the close and miniaturize buttons entirely
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true

            // Prevent hiding via Cmd+H or the app menu
            window.canHide = false

            // Keep the window visible through Mission Control / Exposé
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

            logger.info("Window configured as persistent (AllowDeferral = false)")
        } else {
            // When deferral is allowed, the window is still prominent but closable
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces]

            logger.info("Window configured as floating with deferral enabled")
        }

        // Center the window on screen
        window.center()
    }

    // MARK: - NSWindowDelegate

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Block window close when deferral is not allowed
        if !config.allowDeferral {
            logger.info("Window close blocked — AllowDeferral is false")
            NSSound.beep()
            return false
        }
        return true
    }

    func windowWillMiniaturize(_ notification: Notification) {
        // Prevent minimize when deferral is not allowed by immediately deminiaturizing
        if !config.allowDeferral {
            DispatchQueue.main.async {
                (notification.object as? NSWindow)?.deminiaturize(nil)
            }
        }
    }

    // MARK: - Application Lifecycle

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Block Cmd+Q and programmatic quit attempts when deferral is not allowed,
        // UNLESS we're in a completed/cleanup state (remediation done, portal opened, etc.)
        if !config.allowDeferral {
            if let window = NSApplication.shared.windows.first,
               window.isVisible {
                logger.info("Quit blocked — AllowDeferral is false and window is still active")
                NSSound.beep()
                return .terminateCancel
            }
        }
        return .terminateNow
    }

    func applicationDidResignActive(_ notification: Notification) {
        // When deferral is not allowed, reclaim focus if the user clicks away
        if !config.allowDeferral {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let window = NSApplication.shared.windows.first, window.isVisible {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
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

    // MARK: - Ticket Deferral Tracking

    private static let ticketDeferralCountKey = "TicketDeferralsUsed"

    /// How many times the user has already clicked "I've Already Submitted a Ticket"
    var ticketDeferralsUsed: Int {
        get { UserDefaults.standard.integer(forKey: Self.ticketDeferralCountKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.ticketDeferralCountKey)
            objectWillChange.send()
        }
    }

    /// How many ticket deferrals the user has left
    var ticketDeferralsRemaining: Int {
        max(config.maxTicketDeferrals - ticketDeferralsUsed, 0)
    }

    /// Whether the "I've Already Submitted a Ticket" button should be visible
    var canDeferWithTicket: Bool {
        config.maxTicketDeferrals > 0 && ticketDeferralsRemaining > 0
    }

    /// Use one ticket deferral and dismiss the window
    func useTicketDeferral() {
        ticketDeferralsUsed += 1

        let logger = Logger(subsystem: AppConfiguration.bundleIdentifier, category: "TicketDeferral")
        logger.notice("Ticket deferral used (\(self.ticketDeferralsUsed)/\(self.config.maxTicketDeferrals)). \(self.ticketDeferralsRemaining) remaining.")

        // Hide window and quit — the LaunchAgent will reopen at the next interval
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApplication.shared.windows.first?.orderOut(nil)
            NSApplication.shared.terminate(nil)
        }
    }
}
