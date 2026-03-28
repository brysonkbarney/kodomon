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

        // Prompt for name on first launch
        if engine.state.petName.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.promptForName()
            }
        }
    }

    private func setupPanel() {
        window = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: 240, height: 380),
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
        for bg in BackgroundTheme.allCases {
            let item = NSMenuItem(title: "BG: \(bg.displayName)", action: #selector(setDebugBackground(_:)), keyEquivalent: "")
            item.representedObject = bg.rawValue
            debugMenu.addItem(item)
        }
        debugMenu.addItem(NSMenuItem.separator())
        debugMenu.addItem(NSMenuItem(title: "Add 100 XP", action: #selector(addDebugXP), keyEquivalent: ""))
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

    @objc private func showPanel() {
        window.orderFront(nil)
    }

    @objc private func renamePet() {
        promptForName()
    }

    private func promptForName() {
        let alert = NSAlert()
        alert.messageText = "Name your Kodomon"
        alert.informativeText = "Give your pet a name."
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .informational

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.stringValue = engine.state.petName
        input.placeholderString = "e.g. Kuro, Mochi, Pixel..."
        alert.accessoryView = input

        alert.runModal()

        let name = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty {
            engine.state.petName = name
            StateStore.save(engine.state)
        }
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

    @objc private func resetDebugState() {
        engine.state = PetState.initial()
        StateStore.save(engine.state)
    }

    func applicationWillTerminate(_ notification: Notification) {
        watcher.stopWatching()
        let frame = window.frame
        UserDefaults.standard.set(frame.origin.x, forKey: "panelX")
        UserDefaults.standard.set(frame.origin.y, forKey: "panelY")
    }
}
