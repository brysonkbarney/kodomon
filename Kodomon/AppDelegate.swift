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

    @objc private func showPanel() {
        window.orderFront(nil)
    }

    @objc private func renamePet() {
        promptForName()
    }

    private func promptForName() {
        let alert = NSAlert()
        alert.messageText = "Name your Kodomon"
        alert.informativeText = "Pick a name or type your own."
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .informational

        // Container view
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 120))

        // Three random name buttons
        var currentOptions = NameGenerator.randomThree()
        let buttonStack = NSStackView(frame: NSRect(x: 0, y: 80, width: 260, height: 30))
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 8
        buttonStack.distribution = .fillEqually

        // Text input
        let input = NSTextField(frame: NSRect(x: 0, y: 45, width: 260, height: 24))
        input.stringValue = engine.state.petName.isEmpty ? currentOptions[0] : engine.state.petName
        input.placeholderString = "Type a name..."

        let nameButtons: [NSButton] = (0..<3).map { i in
            let btn = NSButton(title: currentOptions[i], target: nil, action: nil)
            btn.bezelStyle = .rounded
            btn.setButtonType(.momentaryPushIn)
            btn.tag = i
            btn.target = nil
            btn.action = nil
            return btn
        }

        // Click handler — set input text to button title
        class NameButtonHandler: NSObject {
            let input: NSTextField
            init(input: NSTextField) { self.input = input }
            @objc func clicked(_ sender: NSButton) { input.stringValue = sender.title }
        }
        let handler = NameButtonHandler(input: input)
        for btn in nameButtons {
            btn.target = handler
            btn.action = #selector(NameButtonHandler.clicked(_:))
            buttonStack.addArrangedSubview(btn)
        }

        // Reroll button
        class RerollHandler: NSObject {
            let buttons: [NSButton]
            let input: NSTextField
            var excluded: [String] = []
            init(buttons: [NSButton], input: NSTextField) {
                self.buttons = buttons
                self.input = input
            }
            @objc func reroll(_ sender: NSButton) {
                excluded.append(contentsOf: buttons.map { $0.title })
                let newNames = NameGenerator.reroll(excluding: excluded)
                for (i, btn) in buttons.enumerated() {
                    if i < newNames.count { btn.title = newNames[i] }
                }
                input.stringValue = newNames[0]
            }
        }
        let rerollHandler = RerollHandler(buttons: nameButtons, input: input)
        let rerollBtn = NSButton(title: "↻ More names", target: rerollHandler, action: #selector(RerollHandler.reroll(_:)))
        rerollBtn.bezelStyle = .rounded
        rerollBtn.frame = NSRect(x: 70, y: 10, width: 120, height: 24)

        container.addSubview(buttonStack)
        container.addSubview(input)
        container.addSubview(rerollBtn)
        alert.accessoryView = container

        // Keep handlers alive
        objc_setAssociatedObject(alert, "handler", handler, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(alert, "rerollHandler", rerollHandler, .OBJC_ASSOCIATION_RETAIN)

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
        let frame = window.frame
        UserDefaults.standard.set(frame.origin.x, forKey: "panelX")
        UserDefaults.standard.set(frame.origin.y, forKey: "panelY")
    }
}
