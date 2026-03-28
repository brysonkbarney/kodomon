import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var statusItem: NSStatusItem!
    let watcher = ActivityWatcher()
    var engine: PetEngine!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        engine = PetEngine(watcher: watcher)
        watcher.startWatching()

        setupPanel()
        setupMenuBar()
        setupSleepWakeObservers()
    }

    private func setupPanel() {
        window = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: 160, height: 180),
            styleMask: [.fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .normal
        window.collectionBehavior = [.managed]
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden

        if let x = UserDefaults.standard.object(forKey: "panelX") as? CGFloat,
           let y = UserDefaults.standard.object(forKey: "panelY") as? CGFloat {
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let contentView = PetWidgetView()
            .environmentObject(engine!)
        window.contentView = NSHostingView(rootView: contentView)
        window.orderFront(nil)
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "tortoise.fill", accessibilityDescription: "Kodomon")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Kodomon", action: #selector(showPanel), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func setupSleepWakeObservers() {
        let wsc = NSWorkspace.shared.notificationCenter
        wsc.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func handleWake() {
        NSLog("[Kodomon] System woke — checking missed midnights and decay")
        engine.handleWake()
    }

    @objc private func showPanel() {
        window.orderFront(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        watcher.stopWatching()
        let frame = window.frame
        UserDefaults.standard.set(frame.origin.x, forKey: "panelX")
        UserDefaults.standard.set(frame.origin.y, forKey: "panelY")
    }
}
