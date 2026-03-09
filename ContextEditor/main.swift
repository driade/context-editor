import AppKit
import Foundation
import OSLog

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "com.driade.contexteditor", category: "routing")
    private lazy var resolver = EditorResolver(
        appLocator: resolveApplicationURL(for:),
        systemDefaultLocator: systemDefaultApplication(for:)
    )
    private var didReceiveOpenRequest = false
    private var launchTerminationWorkItem: DispatchWorkItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // When launched directly, this app should exit instead of idling in the background.
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if !self.didReceiveOpenRequest {
                self.logger.debug("No files were received after launch; terminating.")
                NSApp.terminate(nil)
            }
        }
        launchTerminationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        didReceiveOpenRequest = true
        launchTerminationWorkItem?.cancel()
        logger.debug("Received \(urls.count, privacy: .public) file(s) to open.")

        for fileURL in urls {
            do {
                try openFile(fileURL)
            } catch {
                present(error: error, for: fileURL)
            }
        }

        NSApp.terminate(nil)
    }

    private func openFile(_ fileURL: URL) throws {
        let resolvedTarget = try resolver.resolveTargetApplication(for: fileURL)
        guard let appURL = resolveApplicationURL(for: resolvedTarget) else {
            let name = resolvedTarget.appName ?? resolvedTarget.bundleIdentifier ?? "unknown"
            throw ConfigError.appNotInstalled(name)
        }

        logger.debug(
            "Opening \(fileURL.path, privacy: .public) with \(appURL.lastPathComponent, privacy: .public)."
        )

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", appURL.path, "--", fileURL.path]
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ConfigError.appNotInstalled(appURL.lastPathComponent)
        }
    }

    private func resolveApplicationURL(for target: TargetApplication) -> URL? {
        let workspace = NSWorkspace.shared

        if let bundleIdentifier = target.bundleIdentifier,
           let url = workspace.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return url
        }

        if let appName = target.appName {
            return workspace.fullPath(forApplication: appName).map(URL.init(fileURLWithPath:))
        }

        return nil
    }

    private func systemDefaultApplication(for fileURL: URL) -> TargetApplication? {
        guard let appURL = NSWorkspace.shared.urlForApplication(toOpen: fileURL) else {
            return nil
        }

        let bundle = Bundle(url: appURL)
        let bundleIdentifier = bundle?.bundleIdentifier
        let ownBundleIdentifier = Bundle.main.bundleIdentifier

        if bundleIdentifier == ownBundleIdentifier {
            return nil
        }

        let appName = appURL.deletingPathExtension().lastPathComponent
        return TargetApplication(appName: appName, bundleIdentifier: bundleIdentifier)
    }

    private func present(error: Error, for fileURL: URL) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Could not open \(fileURL.lastPathComponent)"
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }
}

let delegate = AppDelegate()
let application = NSApplication.shared
application.delegate = delegate
application.run()
