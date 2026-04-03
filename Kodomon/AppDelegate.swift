import AppKit
import SwiftUI
import Combine
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var statusItem: NSStatusItem!
    let watcher = ActivityWatcher()
    var engine: PetEngine!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        engine = PetEngine(watcher: watcher)
        watcher.startWatching()

        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            NSLog("[Kodomon] Notifications permission: %@", granted ? "granted" : "denied")
        }
        _ = NotificationManager.shared

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
        window = PetWindow(
            contentRect: NSRect(x: 200, y: 200, width: 240, height: 380),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.level = .normal
        window.collectionBehavior = [.managed, .canJoinAllSpaces]
        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.setContentSize(NSSize(width: 240, height: 380))
        window.minSize = NSSize(width: 240, height: 380)
        window.maxSize = NSSize(width: 240, height: 380)

        if let x = UserDefaults.standard.object(forKey: "panelX") as? CGFloat,
           let y = UserDefaults.standard.object(forKey: "panelY") as? CGFloat {
            let point = NSPoint(x: x, y: y)
            // Validate position is on a connected screen
            let onScreen = NSScreen.screens.contains { $0.frame.contains(point) }
            if onScreen {
                window.setFrameOrigin(point)
            } else {
                window.center()
            }
        }

        let contentView = PetWidgetView(onMenuTap: { [weak self] in
                self?.openMenuPanel()
            })
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
        menu.addItem(NSMenuItem(title: "Share Card", action: #selector(shareCard), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Rename Pet", action: #selector(renamePet), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Check for Updates", action: #selector(checkUpdates), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        #if DEBUG
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
        debugMenu.addItem(NSMenuItem(title: "Add 10,000 XP", action: #selector(addDebugXPLarge), keyEquivalent: ""))
        debugMenu.addItem(NSMenuItem(title: "Test Evolution", action: #selector(testEvolution), keyEquivalent: ""))
        debugMenu.addItem(NSMenuItem(title: "Test De-Evolution", action: #selector(testDeEvolution), keyEquivalent: ""))
        debugMenu.addItem(NSMenuItem.separator())

        // Neglect state testing
        let neglectMenu = NSMenu()
        for state in [NeglectState.none, .tired, .sad, .sick, .critical, .ranAway] {
            let item = NSMenuItem(title: "Neglect: \(state.rawValue)", action: #selector(setDebugNeglect(_:)), keyEquivalent: "")
            item.representedObject = state.rawValue
            neglectMenu.addItem(item)
        }
        let neglectItem = NSMenuItem(title: "Neglect States", action: nil, keyEquivalent: "")
        neglectItem.submenu = neglectMenu
        debugMenu.addItem(neglectItem)

        // Notification testing
        let notifMenu = NSMenu()
        notifMenu.addItem(NSMenuItem(title: "Test: Tired", action: #selector(testNotifTired), keyEquivalent: ""))
        notifMenu.addItem(NSMenuItem(title: "Test: Streak Warning", action: #selector(testNotifStreak), keyEquivalent: ""))
        notifMenu.addItem(NSMenuItem(title: "Test: Evolution Ready", action: #selector(testNotifEvolution), keyEquivalent: ""))
        notifMenu.addItem(NSMenuItem(title: "Test: Ran Away", action: #selector(testNotifRanAway), keyEquivalent: ""))
        let notifItem = NSMenuItem(title: "Notifications", action: nil, keyEquivalent: "")
        notifItem.submenu = notifMenu
        debugMenu.addItem(notifItem)

        debugMenu.addItem(NSMenuItem.separator())
        debugMenu.addItem(NSMenuItem(title: "Reset State", action: #selector(resetDebugState), keyEquivalent: ""))

        let debugItem = NSMenuItem(title: "Debug", action: nil, keyEquivalent: "")
        debugItem.submenu = debugMenu
        menu.addItem(debugItem)
        #endif

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
        wsc.addObserver(
            self,
            selector: #selector(handleSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
    }

    @objc private func handleWake() {
        NSLog("[Kodomon] System woke — checking missed midnights and decay")
        engine.handleWake()
    }

    @objc private func handleSleep() {
        StateStore.save(engine.state)
    }

    private func openMenuPanel() {
        if let existing = menuWindow {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let isShowing = Binding<Bool>(
            get: { true },
            set: { [weak self] val in
                if !val {
                    self?.menuWindow?.close()
                    self?.menuWindow = nil
                }
            }
        )

        let menuView = MenuPanelView(engine: engine, isShowing: isShowing)

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 420),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.title = "Kodomon"
        w.titlebarAppearsTransparent = true
        w.backgroundColor = NSColor(red: 0.96, green: 0.94, blue: 0.88, alpha: 1)
        w.center()

        let hostingView = NSHostingView(rootView: menuView)
        w.contentView = hostingView
        w.makeKeyAndOrderFront(nil)

        menuWindow = w
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
        if let w = window, w.isVisible || w.contentView != nil {
            w.orderFront(nil)
        } else {
            window = nil
            setupPanel()
        }
    }

    var welcomeWindow: NSWindow?
    var menuWindow: NSWindow?

    @objc private func shareCard() {
        ShareCardGenerator.copyToClipboard(state: engine.state)

        // Also save to desktop
        ShareCardGenerator.saveToDesktop(state: engine.state)

        // Show confirmation
        let alert = NSAlert()
        alert.messageText = "Share Card Ready!"
        alert.informativeText = "Card copied to clipboard and saved to Desktop. Paste it anywhere!"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func checkUpdates() {
        UpdateChecker.shared.checkForUpdates()
    }

    @objc private func renamePet() {
        let alert = NSAlert()
        alert.messageText = "Rename your Kodomon"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .informational
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.stringValue = engine.state.petName
        alert.accessoryView = input
        if alert.runModal() == .alertFirstButtonReturn {
            let name = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                engine.state.petName = name
                StateStore.save(engine.state)
            }
        }
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

    #if DEBUG
    @objc private func setDebugStage(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let stage = Stage(rawValue: rawValue) else { return }
        engine.state.stage = stage
        engine.state.totalXP = stage.xpThreshold
        engine.state.activeDays = stage.requiredActiveDays
        engine.state.currentStreak = stage.requiredStreak
        engine.state.stageReachedDate = Date()
        engine.state.neglectState = .none
        StateStore.save(engine.state)
    }

    @objc private func setDebugXP(_ sender: NSMenuItem) {
        guard let pct = sender.representedObject as? Double else { return }
        guard let next = engine.state.stage.nextStage else { return }
        let current = engine.state.stage.xpThreshold
        let range = next.xpThreshold - current
        engine.state.totalXP = current + (range * max(0, min(1, pct)))
        StateStore.save(engine.state)
    }

    @objc private func addDebugXPLarge() {
        engine.state.totalXP += 10000
        engine.state.todayXP += 10000
        engine.state.lifetimeXP += 10000
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
        guard let to = from.nextStage else { return }
        engine.state.stage = to
        engine.state.totalXP = to.xpThreshold
        engine.state.activeDays = to.requiredActiveDays
        engine.state.currentStreak = to.requiredStreak
        engine.state.stageReachedDate = Date()
        StateStore.save(engine.state)
        engine.evolutionEvent = (from: from, to: to)
    }

    @objc private func testDeEvolution() {
        let from = engine.state.stage
        guard let to = from.previousStage else { return }
        engine.state.stage = to
        engine.state.totalXP = to.xpThreshold
        engine.state.activeDays = to.requiredActiveDays
        engine.state.currentStreak = to.requiredStreak
        engine.state.stageReachedDate = Date()
        StateStore.save(engine.state)
        engine.deEvolutionEvent = (from: from, to: to)
    }

    @objc private func setDebugNeglect(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let state = NeglectState(rawValue: rawValue) else { return }
        engine.state.neglectState = state
        StateStore.save(engine.state)
    }

    @objc private func testNotifTired() {
        NotificationManager.shared.sendTiredNotification(petName: engine.state.petName)
    }

    @objc private func testNotifStreak() {
        NotificationManager.shared.sendStreakWarningNow(petName: engine.state.petName)
    }

    @objc private func testNotifEvolution() {
        NotificationManager.shared.sendEvolutionReadyNotification(petName: engine.state.petName)
    }

    @objc private func testNotifRanAway() {
        NotificationManager.shared.sendPetRanAwayNotification(petName: engine.state.petName)
    }

    @objc private func resetDebugState() {
        let alert = NSAlert()
        alert.messageText = "Reset all pet data?"
        alert.informativeText = "This cannot be undone. Your pet and all progress will be lost."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        engine.state = PetState.initial()
        StateStore.save(engine.state)
    }
    #endif

    func applicationWillTerminate(_ notification: Notification) {
        watcher.stopWatching()
        if let w = window {
            let frame = w.frame
            UserDefaults.standard.set(frame.origin.x, forKey: "panelX")
            UserDefaults.standard.set(frame.origin.y, forKey: "panelY")
        }
    }
}

// Window subclass that accepts first mouse click without needing to focus first
class PetWindow: NSWindow {
    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown {
            makeKeyAndOrderFront(nil)
        }
        super.sendEvent(event)
    }
}

