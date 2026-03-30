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

        setupMenuBar()
        setupSleepWakeObservers()

        if engine.state.petName.isEmpty {
            // First launch — show welcome, don't show game card yet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.promptForName()
            }
        } else {
            // Returning user — show game card directly
            setupPanel()
        }
    }

    private func setupPanel() {
        window = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: 240, height: 380),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .normal
        window.collectionBehavior = [.managed]
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.setContentSize(NSSize(width: 240, height: 380))
        window.minSize = NSSize(width: 240, height: 380)
        window.maxSize = NSSize(width: 240, height: 380)

        if let x = UserDefaults.standard.object(forKey: "panelX") as? CGFloat,
           let y = UserDefaults.standard.object(forKey: "panelY") as? CGFloat {
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let contentView = PetWidgetView()
            .environmentObject(engine!)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.layer?.isOpaque = false
        hostingView.layer?.masksToBounds = true
        hostingView.layer?.cornerRadius = 12
        window.contentView = hostingView
        window.orderFront(nil)
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(named: "menubarIcon")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Kodomon", action: #selector(showPanel), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Rename Pet", action: #selector(renamePet), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        // Debug menu
        let debugMenu = NSMenu()
        for stage in Stage.allCases {
            let item = NSMenuItem(title: stage.displayName, action: #selector(setDebugStage(_:)), keyEquivalent: "")
            item.representedObject = stage.rawValue
            debugMenu.addItem(item)
        }
        debugMenu.addItem(NSMenuItem.separator())
        let xpItems: [(String, Double)] = [("Set 0% XP", 0), ("Set 25% XP", 0.25), ("Set 50% XP", 0.5), ("Set 80% XP", 0.8), ("Set 95% XP", 0.95)]
        for (title, pct) in xpItems {
            let item = NSMenuItem(title: title, action: #selector(setDebugXP(_:)), keyEquivalent: "")
            item.representedObject = pct
            debugMenu.addItem(item)
        }
        debugMenu.addItem(NSMenuItem.separator())
        let noneItem = NSMenuItem(title: "BG: None", action: #selector(setDebugBackground(_:)), keyEquivalent: "")
        noneItem.representedObject = "none"
        debugMenu.addItem(noneItem)
        for bg in BackgroundTheme.allCases {
            let item = NSMenuItem(title: "BG: \(bg.displayName)", action: #selector(setDebugBackground(_:)), keyEquivalent: "")
            item.representedObject = bg.rawValue
            debugMenu.addItem(item)
        }
        debugMenu.addItem(NSMenuItem.separator())
        debugMenu.addItem(NSMenuItem(title: "Add 100 XP", action: #selector(addDebugXP), keyEquivalent: ""))
        debugMenu.addItem(NSMenuItem(title: "Test Evolution", action: #selector(testEvolution), keyEquivalent: ""))
        debugMenu.addItem(NSMenuItem(title: "Reset State", action: #selector(resetDebugState), keyEquivalent: ""))

        let debugItem = NSMenuItem(title: "Debug", action: nil, keyEquivalent: "")
        debugItem.submenu = debugMenu
        menu.addItem(debugItem)

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

    private func showLoadingScreen() {
        let loadingView = LoadingView()
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 300),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        w.backgroundColor = .clear
        w.isOpaque = false
        w.hasShadow = true
        w.level = .floating
        w.center()
        let hostingView = NSHostingView(rootView: loadingView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        w.contentView = hostingView
        w.makeKeyAndOrderFront(nil)

        // After 1.5 seconds, close loading and show game card
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            w.orderOut(nil)
            self?.setupPanel()
        }
    }

    @objc private func showPanel() {
        if window != nil {
            window.orderFront(nil)
        } else {
            setupPanel()
        }
    }

    var welcomeWindow: NSWindow?

    @objc private func renamePet() {
        promptForName()
    }

    private func promptForName() {
        let welcomeView = WelcomeView { [weak self] name in
            guard let self = self else { return }
            self.engine.state.petName = name
            StateStore.save(self.engine.state)
            // Show loading screen, then transition to game card
            DispatchQueue.main.async {
                self.welcomeWindow?.orderOut(nil)
                self.welcomeWindow = nil
                self.showLoadingScreen()
            }
        }

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 440),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        w.backgroundColor = .clear
        w.isOpaque = false
        w.hasShadow = true
        w.level = .floating
        w.center()

        let hostingView = NSHostingView(rootView: welcomeView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        w.contentView = hostingView
        w.makeKeyAndOrderFront(nil)

        welcomeWindow = w
    }

    @objc private func setDebugStage(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let stage = Stage(rawValue: rawValue) else { return }
        engine.state.stage = stage
        engine.state.totalXP = stage.xpThreshold
        engine.state.activeDays = stage.requiredActiveDays
        engine.state.currentStreak = stage.requiredStreak
        StateStore.save(engine.state)
    }

    @objc private func setDebugXP(_ sender: NSMenuItem) {
        guard let pct = sender.representedObject as? Double else { return }
        guard let next = engine.state.stage.nextStage else { return }
        let current = engine.state.stage.xpThreshold
        let range = next.xpThreshold - current
        engine.state.totalXP = current + (range * pct)
        StateStore.save(engine.state)
    }

    @objc private func addDebugXP() {
        engine.state.totalXP += 100
        engine.state.todayXP += 100
        engine.state.lifetimeXP += 100
        StateStore.save(engine.state)
    }

    @objc private func setDebugBackground(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String else { return }
        engine.state.activeBackground = rawValue
        StateStore.save(engine.state)
    }

    @objc private func testEvolution() {
        let from = engine.state.stage
        let to = from.nextStage ?? .kamisama
        engine.evolutionEvent = (from: from, to: to)
    }

    @objc private func resetDebugState() {
        engine.state = PetState.initial()
        StateStore.save(engine.state)
    }

    func applicationWillTerminate(_ notification: Notification) {
        watcher.stopWatching()
        if let w = window {
            let frame = w.frame
            UserDefaults.standard.set(frame.origin.x, forKey: "panelX")
            UserDefaults.standard.set(frame.origin.y, forKey: "panelY")
        }
    }
}
