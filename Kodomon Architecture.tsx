import { useState } from "react";

const ACCENT = { purple:"#7F77DD", teal:"#1D9E75", coral:"#D85A30", amber:"#BA7517", gray:"#5F5E5A", red:"#E24B4A" };

const Tag = ({c=ACCENT.purple, children}) => (
  <span style={{display:"inline-block",padding:"1px 8px",borderRadius:20,fontSize:11,fontWeight:500,
    marginRight:5,marginBottom:3,background:c+"22",color:c,border:`1px solid ${c}44`}}>{children}</span>
);

const Card = ({title, accent=ACCENT.purple, children, mono}) => (
  <div style={{borderRadius:10,border:"1px solid var(--color-border-tertiary)",
    background:"var(--color-background-secondary)",marginBottom:14,overflow:"hidden"}}>
    <div style={{padding:"8px 14px",borderBottom:"1px solid var(--color-border-tertiary)",
      borderLeft:`3px solid ${accent}`,fontSize:13,fontWeight:500,color:"var(--color-text-primary)"}}>{title}</div>
    <div style={{padding:"12px 14px",fontSize:mono?12:13,color:"var(--color-text-secondary)",
      lineHeight:1.7,fontFamily:mono?"var(--font-mono)":undefined}}>{children}</div>
  </div>
);

const File = ({name,desc,accent=ACCENT.gray}) => (
  <div style={{display:"flex",gap:10,padding:"6px 0",borderBottom:"1px solid var(--color-border-tertiary)"}}>
    <span style={{fontFamily:"var(--font-mono)",fontSize:12,color:accent,minWidth:240,flexShrink:0}}>{name}</span>
    <span style={{fontSize:12,color:"var(--color-text-tertiary)"}}>{desc}</span>
  </div>
);

const sections = ["overview","project","layer1","layer2","layer3","layer4","data","build"];
const nav = {
  overview:"Overview",project:"Project structure",
  layer1:"Layer 1 — hooks",layer2:"Layer 2 — watcher",
  layer3:"Layer 3 — engine",layer4:"Layer 4 — UI",
  data:"Data & persistence",build:"Build order"
};

const pages = {
  overview: () => (
    <div>
      <p style={{fontSize:13,lineHeight:1.8,color:"var(--color-text-secondary)",marginBottom:16}}>
        Kodomon is a pure Swift macOS app — no Electron, no web views, no server. It runs as a menubar agent (no dock icon), shows a floating <code>NSPanel</code> widget anywhere on screen, and stays alive silently in the background watching for coding activity.
      </p>
      <Card title="Four-layer architecture" accent={ACCENT.purple}>
        <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:10}}>
          {[
            {n:"Layer 1", label:"Claude Code hooks", desc:"Shell scripts installed into ~/.claude/settings.json. Fire on SessionStart, PostToolUse, Stop. Write events to a shared JSONL file.", c:ACCENT.teal},
            {n:"Layer 2", label:"Activity watcher", desc:"Swift FileSystemWatcher monitors the JSONL event file + git hooks + file system. Translates raw events into scored XP actions.", c:ACCENT.amber},
            {n:"Layer 3", label:"Pet stats engine", desc:"Pure Swift, rule-based. Consumes scored actions, applies XP math, decay, mood, streak. Persists state to local JSON.", c:ACCENT.coral},
            {n:"Layer 4", label:"UI layer", desc:"SwiftUI NSPanel widget + menubar icon. Renders pet sprite, stats, animations. Sends macOS notifications. Generates share card.", c:ACCENT.purple},
          ].map(l => (
            <div key={l.n} style={{padding:"10px 12px",borderRadius:8,border:`1px solid ${l.c}44`,background:l.c+"11"}}>
              <div style={{fontSize:11,fontWeight:500,color:l.c,marginBottom:3}}>{l.n}</div>
              <div style={{fontSize:12,fontWeight:500,color:"var(--color-text-primary)",marginBottom:4}}>{l.label}</div>
              <div style={{fontSize:11,color:"var(--color-text-secondary)",lineHeight:1.6}}>{l.desc}</div>
            </div>
          ))}
        </div>
      </Card>
      <Card title="Key technical decisions" accent={ACCENT.amber}>
        <ul style={{margin:0,paddingLeft:16,fontSize:13}}>
          <li><strong>100% local.</strong> No server, no account, no network calls (except optional opt-in leaderboard). Everything reads/writes to <code>~/.kodomon/</code>.</li>
          <li><strong>NSPanel not dock window.</strong> Lil Agents lives in the dock — Kodomon is a floating widget that can be positioned anywhere, like a desktop widget. Uses <code>collectionBehavior = .canJoinAllSpaces</code> so it follows you across desktops.</li>
          <li><strong>LSUIElement = YES.</strong> No dock icon. Lives in menubar only. Same pattern as Lil Agents.</li>
          <li><strong>Claude Code hooks as the data source.</strong> The hooks system fires shell scripts on real Claude Code events — SessionStart, PostToolUse (Write/Edit), Stop. This is the cleanest integration point, no polling needed.</li>
          <li><strong>Git hooks as secondary source.</strong> A post-commit hook script writes commit metadata (lines changed, message) to the same JSONL event file.</li>
          <li><strong>Swift Combine for reactivity.</strong> The watcher publishes events via Combine publishers. The engine subscribes. The UI subscribes to the engine's state. Clean one-way data flow.</li>
        </ul>
      </Card>
      <Card title="Lil Agents reference" accent={ACCENT.gray}>
        <p style={{margin:"0 0 6px"}}>Key things learned from studying Lil Agents:</p>
        <ul style={{margin:0,paddingLeft:16,fontSize:13}}>
          <li>Uses <strong>transparent HEVC video</strong> for character animations — pre-rendered video with alpha channel, not live-drawn sprites. Consider this for Kodomon's pet animations too.</li>
          <li>Uses <strong>Sparkle</strong> for auto-updates — copy this pattern exactly.</li>
          <li>100% Swift, <code>AppKit App Delegate</code> lifecycle (not SwiftUI App), <code>NSHostingView</code> to embed SwiftUI views.</li>
          <li>Characters positioned relative to dock using <code>NSScreen</code> APIs to calculate dock height and position.</li>
        </ul>
      </Card>
    </div>
  ),

  project: () => (
    <div>
      <Card title="Xcode project setup" accent={ACCENT.teal}>
        <ul style={{margin:0,paddingLeft:16,fontSize:13}}>
          <li>New macOS App in Xcode — <strong>SwiftUI interface, AppKit App Delegate lifecycle</strong></li>
          <li>Bundle ID: <code>com.kodomon.app</code></li>
          <li>Deployment target: <strong>macOS 14.0+ (Sonoma)</strong> — same as Lil Agents</li>
          <li>Set <code>LSUIElement = YES</code> in Info.plist — removes dock icon</li>
          <li>Entitlements: none needed for v1 (no sandboxing, reads local files only)</li>
          <li>Add <strong>Sparkle</strong> via Swift Package Manager for auto-updates</li>
        </ul>
      </Card>
      <Card title="File structure" accent={ACCENT.purple}>
        <div style={{fontFamily:"var(--font-mono)",fontSize:11,lineHeight:1.9}}>
          <File name="Kodomon/" desc="" accent={ACCENT.purple}/>
          <File name="  App/" desc="" accent={ACCENT.gray}/>
          <File name="    AppDelegate.swift" desc="NSPanel setup, menubar item, lifecycle" accent={ACCENT.teal}/>
          <File name="    KodomonApp.swift" desc="@main entry, @NSApplicationDelegateAdaptor" accent={ACCENT.teal}/>
          <File name="  Watcher/" desc="" accent={ACCENT.gray}/>
          <File name="    ActivityWatcher.swift" desc="FSEvents watcher for JSONL file" accent={ACCENT.amber}/>
          <File name="    GitWatcher.swift" desc="Watches ~/.kodomon/git-events.jsonl" accent={ACCENT.amber}/>
          <File name="    EventParser.swift" desc="Parses raw JSONL → typed ActivityEvent" accent={ACCENT.amber}/>
          <File name="  Engine/" desc="" accent={ACCENT.gray}/>
          <File name="    PetEngine.swift" desc="Core ObservableObject, all game logic" accent={ACCENT.coral}/>
          <File name="    XPCalculator.swift" desc="XP rules, diminishing returns, caps" accent={ACCENT.coral}/>
          <File name="    DecayManager.swift" desc="Time-based decay, neglect states" accent={ACCENT.coral}/>
          <File name="    MoodEngine.swift" desc="Mood score, modifiers" accent={ACCENT.coral}/>
          <File name="    EventEngine.swift" desc="Random event system, triggers" accent={ACCENT.coral}/>
          <File name="    StreakTracker.swift" desc="Streak calculation, multipliers" accent={ACCENT.coral}/>
          <File name="  UI/" desc="" accent={ACCENT.gray}/>
          <File name="    PetWidgetView.swift" desc="Main floating NSPanel SwiftUI view" accent={ACCENT.purple}/>
          <File name="    PetSpriteView.swift" desc="Pixel art / HEVC animation renderer" accent={ACCENT.purple}/>
          <File name="    StatsView.swift" desc="XP bar, mood, streak display" accent={ACCENT.purple}/>
          <File name="    MenuBarView.swift" desc="Menubar icon + popover" accent={ACCENT.purple}/>
          <File name="    ShareCardView.swift" desc="Wrapped card, PNG export" accent={ACCENT.purple}/>
          <File name="    NotificationManager.swift" desc="UserNotifications wrapper" accent={ACCENT.purple}/>
          <File name="  Persistence/" desc="" accent={ACCENT.gray}/>
          <File name="    PetState.swift" desc="Codable struct — single source of truth" accent={ACCENT.teal}/>
          <File name="    StateStore.swift" desc="Read/write ~/.kodomon/state.json" accent={ACCENT.teal}/>
          <File name="  Hooks/" desc="Shell scripts, not Swift" accent={ACCENT.gray}/>
          <File name="    install-hooks.sh" desc="Installs all hooks, run once on setup" accent={ACCENT.amber}/>
          <File name="    kodomon-claude-event.sh" desc="Claude Code hook → writes to JSONL" accent={ACCENT.amber}/>
          <File name="    kodomon-git-commit.sh" desc="post-commit hook → writes to JSONL" accent={ACCENT.amber}/>
          <File name="  Assets.xcassets" desc="Pet sprites, icons, themes" accent={ACCENT.gray}/>
        </div>
      </Card>
    </div>
  ),

  layer1: () => (
    <div>
      <p style={{fontSize:13,color:"var(--color-text-secondary)",lineHeight:1.7,marginBottom:14}}>
        Layer 1 is shell scripts, not Swift. These get installed into <code>~/.claude/settings.json</code> and into each repo's <code>.git/hooks/</code>. They are the only bridge between Claude Code's world and Kodomon's world. Their job is simple: detect an event, write a JSON line to a shared file.
      </p>
      <Card title="Claude Code hook — ~/.claude/settings.json" accent={ACCENT.teal} mono>
        {[
          '{',
          '  "hooks": {',
          '    "SessionStart": [{"hooks": [{"type": "command",',
          '      "command": "~/.kodomon/hooks/session-start.sh", "async": true}]}],',
          '    "PostToolUse": [{"matcher": "Write|Edit|MultiEdit",',
          '      "hooks": [{"type": "command",',
          '      "command": "~/.kodomon/hooks/file-event.sh", "async": true}]}],',
          '    "Stop": [{"hooks": [{"type": "command",',
          '      "command": "~/.kodomon/hooks/session-stop.sh", "async": true}]}]',
          '  }',
          '}',
        ].join('\n')}
      </Card>
      <Card title="What each hook writes to ~/.kodomon/events.jsonl" accent={ACCENT.amber} mono>
        {[
          '// SessionStart',
          '{"type":"session_start","ts":1711234567,"session_id":"abc123","cwd":"/my/project"}',
          '',
          '// PostToolUse (Write/Edit)',
          '{"type":"file_write","ts":1711234570,"file":"/my/project/src/app.ts","lines_added":42,"lines_removed":5}',
          '',
          '// Stop',
          '{"type":"session_stop","ts":1711236000,"session_id":"abc123","duration_secs":1433}',
          '',
          '// Git post-commit',
          '{"type":"git_commit","ts":1711234900,"hash":"a1b2c3","lines_added":127,"lines_removed":30,"files":3}',
        ].join('\n')}
      </Card>
      <Card title="Git post-commit hook — ~/.kodomon/hooks/git-commit.sh" accent={ACCENT.amber} mono>
        {[
          '#!/bin/bash',
          '# Installed by Kodomon into each repos .git/hooks/post-commit',
          '# (or globally via git config --global core.hooksPath)',
          '',
          'ADDED=$(git diff HEAD~1 HEAD --stat | grep "insertions" | grep -o "[0-9]* insertion" | grep -o "[0-9]*")',
          'REMOVED=$(git diff HEAD~1 HEAD --stat | grep "deletions" | grep -o "[0-9]* deletion" | grep -o "[0-9]*")',
          'FILES=$(git diff HEAD~1 HEAD --stat | tail -1 | grep -o "[0-9]* file" | grep -o "[0-9]*")',
          'HASH=$(git rev-parse --short HEAD)',
          '',
          'echo "{\\"type\\":\\"git_commit\\",\\"ts\\":$(date +%s),\\"hash\\":\\"$HASH\\"," \\',
          '  "\\"lines_added\\":${ADDED:-0},\\"lines_removed\\":${REMOVED:-0},\\"files\\":${FILES:-0}}" \\',
          '  >> ~/.kodomon/events.jsonl',
        ].join('\n')}
      </Card>
      <Card title="Hook installer — run once on app first launch" accent={ACCENT.teal}>
        <p style={{margin:"0 0 8px"}}>On first launch, Kodomon's <code>AppDelegate</code> checks if hooks are installed. If not, it prompts the user and runs <code>install-hooks.sh</code> which:</p>
        <ul style={{margin:0,paddingLeft:16,fontSize:13}}>
          <li>Creates <code>~/.kodomon/</code> directory</li>
          <li>Copies hook scripts to <code>~/.kodomon/hooks/</code></li>
          <li>Merges hook config into <code>~/.claude/settings.json</code> (doesn't overwrite existing hooks)</li>
          <li>Sets <code>git config --global core.hooksPath ~/.kodomon/git-hooks/</code> for global git hook</li>
          <li>Creates empty <code>~/.kodomon/events.jsonl</code></li>
        </ul>
      </Card>
    </div>
  ),

  layer2: () => (
    <div>
      <p style={{fontSize:13,color:"var(--color-text-secondary)",lineHeight:1.7,marginBottom:14}}>
        The watcher is a Swift class that monitors <code>~/.kodomon/events.jsonl</code> using <code>FSEvents</code> (via <code>DispatchSource</code>). When the file changes, it reads new lines, parses them, and publishes typed events via Combine.
      </p>
      <Card title="ActivityWatcher.swift — skeleton" accent={ACCENT.amber} mono>
        {[
          'import Foundation',
          'import Combine',
          '',
          'class ActivityWatcher: ObservableObject {',
          '  private var fileDescriptor: Int32 = -1',
          '  private var source: DispatchSourceFileSystemObject?',
          '  private var lastReadOffset: UInt64 = 0',
          '  ',
          '  let eventPublisher = PassthroughSubject<ActivityEvent, Never>()',
          '  ',
          '  func startWatching() {',
          '    let path = FileManager.default',
          '      .homeDirectoryForCurrentUser',
          '      .appendingPathComponent(".kodomon/events.jsonl").path',
          '    ',
          '    fileDescriptor = open(path, O_EVTONLY)',
          '    source = DispatchSource.makeFileSystemObjectSource(',
          '      fileDescriptor: fileDescriptor,',
          '      eventMask: .write,',
          '      queue: .global(qos: .utility)',
          '    )',
          '    source?.setEventHandler { [weak self] in',
          '      self?.readNewLines()',
          '    }',
          '    source?.resume()',
          '  }',
          '  ',
          '  private func readNewLines() {',
          '    // Read only new bytes since last offset',
          '    // Parse each new line as ActivityEvent',
          '    // Publish via eventPublisher',
          '  }',
          '}',
        ].join('\n')}
      </Card>
      <Card title="ActivityEvent — typed events from JSONL" accent={ACCENT.coral} mono>
        {[
          'enum ActivityEvent {',
          '  case sessionStart(sessionId: String, cwd: String, timestamp: Date)',
          '  case sessionStop(sessionId: String, durationSecs: Int, timestamp: Date)',
          '  case fileWrite(filePath: String, linesAdded: Int, linesRemoved: Int, timestamp: Date)',
          '  case gitCommit(hash: String, linesAdded: Int, linesRemoved: Int, files: Int, timestamp: Date)',
          '}',
        ].join('\n')}
      </Card>
      <Card title="What the watcher scores" accent={ACCENT.amber}>
        <p style={{margin:"0 0 8px"}}>The watcher doesn't apply XP — it scores events into <code>ScoredAction</code>s with a type and raw value. The engine applies the actual XP math.</p>
        <ul style={{margin:0,paddingLeft:16,fontSize:13}}>
          <li><code>gitCommit</code> → scores commit size tier (small/medium/large/huge/legendary)</li>
          <li><code>fileWrite</code> → scores lines added, file type (for variety tracking)</li>
          <li><code>sessionStart</code> / <code>sessionStop</code> → scores session duration in minutes</li>
          <li>File type tracking: extracts extension from path, feeds variety bonus logic</li>
        </ul>
      </Card>
    </div>
  ),

  layer3: () => (
    <div>
      <p style={{fontSize:13,color:"var(--color-text-secondary)",lineHeight:1.7,marginBottom:14}}>
        The engine is the heart of Kodomon. It's a pure Swift <code>ObservableObject</code> with no UI dependencies. It consumes <code>ScoredAction</code>s, applies all GDD rules, and publishes a single <code>PetState</code> that the UI renders.
      </p>
      <Card title="PetState — single source of truth" accent={ACCENT.coral} mono>
        {[
          'struct PetState: Codable {',
          '  // Identity',
          '  var daysAlive: Int',
          '  var activeDays: Int',
          '  var createdAt: Date',
          '  // XP',
          '  var totalXP: Double',
          '  var todayXP: Double',
          '  var todaySessionMins: Int',
          '  var lifetimeXP: Double',
          '  // Evolution',
          '  var stage: Stage        // egg, kobito, kani, kamisama',
          '  var currentStreak: Int',
          '  var longestStreak: Int',
          '  // Mood',
          '  var mood: Double        // 0-100',
          '  var neglectState: NeglectState',
          '  // Cosmetics',
          '  var equippedAccessories: [String]',
          '  var unlockedItems: Set<String>',
          '  var activeBackground: String',
          '  // Stats (for share card)',
          '  var totalCommits: Int',
          '  var totalLinesWritten: Int',
          '  var biggestCommitLines: Int',
          '  var lastActiveDate: Date',
          '}',
        ].join('\n')}
      </Card>
      <Card title="PetEngine responsibilities" accent={ACCENT.coral}>
        <ul style={{margin:0,paddingLeft:16,fontSize:13}}>
          <li><strong>XP application</strong> — receives ScoredActions, applies daily cap, diminishing returns, streak multiplier, mood multiplier</li>
          <li><strong>Midnight timer</strong> — resets <code>todayXP</code>, updates streak, checks if active day qualifies, triggers decay if applicable</li>
          <li><strong>Decay manager</strong> — runs on a 30-min timer, checks <code>lastActiveDate</code>, applies XP decay if neglect thresholds crossed</li>
          <li><strong>Evolution checker</strong> — after each XP update, checks if stage gate conditions are met (XP + activeDays + streak)</li>
          <li><strong>De-evolution checker</strong> — if XP drops below stage floor (with grace period), triggers stage regression</li>
          <li><strong>Random event engine</strong> — 30% daily chance, picks event from pool, modifies state accordingly</li>
          <li><strong>Unlock checker</strong> — after state changes, evaluates all unlock conditions, adds to <code>unlockedItems</code></li>
          <li><strong>State persistence</strong> — saves state to JSON after every meaningful change via <code>StateStore</code></li>
        </ul>
      </Card>
      <Card title="Midnight timer pattern" accent={ACCENT.amber} mono>
        {[
          '// In PetEngine.init()',
          'scheduleMidnightReset()',
          '',
          'private func scheduleMidnightReset() {',
          '  let cal = Calendar.current',
          '  let tomorrow = cal.startOfDay(for: Date().addingTimeInterval(86400))',
          '  let interval = tomorrow.timeIntervalSinceNow',
          '  Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in',
          '    self?.performMidnightReset()',
          '    self?.scheduleMidnightReset()',
          '  }',
          '}',
          '',
          'private func performMidnightReset() {',
          '  // 1. Check if today was an active day',
          '  // 2. Update streak (increment or break)',
          '  // 3. Reset todayXP + todaySessionMins',
          '  // 4. Apply decay if missed day',
          '  // 5. Pick random event for tomorrow (30% chance)',
          '  // 6. Save state',
          '}',
        ].join('\n')}
      </Card>
    </div>
  ),

  layer4: () => (
    <div>
      <p style={{fontSize:13,color:"var(--color-text-secondary)",lineHeight:1.7,marginBottom:14}}>
        The UI is an <code>NSPanel</code> (floating, always-on-top, transparent background) hosting SwiftUI views via <code>NSHostingView</code>. Plus a menubar extra for quick access and settings.
      </p>
      <Card title="AppDelegate.swift — panel setup" accent={ACCENT.purple} mono>
        {[
          'class AppDelegate: NSObject, NSApplicationDelegate {',
          '  var panel: NSPanel!',
          '  var statusItem: NSStatusItem!',
          '',
          '  func applicationDidFinishLaunching(_ n: Notification) {',
          '    NSApp.setActivationPolicy(.accessory)',
          '',
          '    panel = NSPanel(',
          '      contentRect: NSRect(x: 0, y: 200, width: 160, height: 160),',
          '      styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],',
          '      backing: .buffered, defer: false',
          '    )',
          '    panel.level = .floating',
          '    panel.collectionBehavior = [.canJoinAllSpaces, .stationary]',
          '    panel.isMovableByWindowBackground = true',
          '    panel.backgroundColor = .clear',
          '    panel.isOpaque = false',
          '    panel.hasShadow = false',
          '',
          '    let contentView = PetWidgetView()',
          '      .environmentObject(PetEngine.shared)',
          '    panel.contentView = NSHostingView(rootView: contentView)',
          '    panel.orderFront(nil)',
          '',
          '    statusItem = NSStatusBar.system.statusItem(',
          '      withLength: NSStatusItem.squareLength)',
          '    // ... setup menubar popover',
          '  }',
          '}',
        ].join('\n')}
      </Card>
      <Card title="PetWidgetView — what the user sees" accent={ACCENT.purple}>
        <ul style={{margin:0,paddingLeft:16,fontSize:13}}>
          <li>Small square widget (~160×180pt), fully transparent background</li>
          <li>Pet sprite centered — either pixel art <code>Image</code> frames or HEVC video with alpha (like Lil Agents)</li>
          <li>Thin XP bar at the bottom, mood indicator dot top-right</li>
          <li>Right-click opens context menu: stats, settings, share card, quit</li>
          <li>Draggable — user can reposition anywhere on screen, position saved to <code>UserDefaults</code></li>
          <li>Animates in response to engine events via <code>@EnvironmentObject PetEngine</code></li>
        </ul>
      </Card>
      <Card title="Share card — PNG export" accent={ACCENT.purple} mono>
        {[
          '@MainActor func generateShareCard() -> NSImage? {',
          '  let card = ShareCardView(state: engine.state)',
          '    .frame(width: 800, height: 420)',
          '  let renderer = ImageRenderer(content: card)',
          '  renderer.scale = 2.0  // retina',
          '  return renderer.nsImage',
          '}',
          '',
          'func exportCard() {',
          '  guard let img = generateShareCard() else { return }',
          '  let pasteboard = NSPasteboard.general',
          '  pasteboard.clearContents()',
          '  pasteboard.writeObjects([img])',
          '  // Also offer save panel for PNG export',
          '}',
        ].join('\n')}
      </Card>
      <Card title="Notifications" accent={ACCENT.amber} mono>
        {[
          '// Request permission on first launch',
          'UNUserNotificationCenter.current()',
          '  .requestAuthorization(options: [.alert, .sound]) { _, _ in }',
          '',
          'func sendNeglectNotification(_ state: NeglectState) {',
          '  let content = UNMutableNotificationContent()',
          '  content.title = "Kodomon"',
          '  content.body = "\\u300ood naka suita...\\u3001 Kodomon is getting hungry."',
          '  let trigger = UNTimeIntervalNotificationTrigger(',
          '    timeInterval: 1, repeats: false)',
          '  let req = UNNotificationRequest(',
          '    identifier: "neglect-\\(state)",',
          '    content: content, trigger: trigger)',
          '  UNUserNotificationCenter.current().add(req)',
          '}',
        ].join('\n')}
      </Card>
    </div>
  ),

  data: () => (
    <div>
      <Card title="File layout — ~/.kodomon/" accent={ACCENT.teal} mono>
{`~/.kodomon/
  state.json          ← PetState (read on launch, written after every change)
  events.jsonl        ← append-only event log (hooks write here)
  stats.json          ← lifetime stats (never resets, for share card)
  hooks/
    session-start.sh  ← Claude Code hook scripts
    file-event.sh
    session-stop.sh
    git-commit.sh     ← git post-commit hook
    install-hooks.sh  ← run once on setup`}
      </Card>
      <Card title="state.json — sample" accent={ACCENT.coral} mono>
        {[
          '{',
          '  "daysAlive": 23,',
          '  "activeDays": 18,',
          '  "createdAt": "2026-03-01T09:00:00Z",',
          '  "totalXP": 3842.5,',
          '  "todayXP": 145.0,',
          '  "todaySessionMins": 67,',
          '  "lifetimeXP": 4200.0,',
          '  "stage": "kobito",',
          '  "currentStreak": 5,',
          '  "longestStreak": 8,',
          '  "mood": 72.4,',
          '  "neglectState": "none",',
          '  "equippedAccessories": ["tiny_headband"],',
          '  "unlockedItems": ["tiny_headband", "first_hatch"],',
          '  "activeBackground": "tokyo_night",',
          '  "totalCommits": 47,',
          '  "totalLinesWritten": 8234,',
          '  "biggestCommitLines": 312,',
          '  "lastActiveDate": "2026-03-23T18:42:00Z"',
          '}',
        ].join('\n')}
      </Card>
      <Card title="StateStore — read/write pattern" accent={ACCENT.teal} mono>
        {[
          'class StateStore {',
          '  static let path = FileManager.default',
          '    .homeDirectoryForCurrentUser',
          '    .appendingPathComponent(".kodomon/state.json")',
          '',
          '  static func load() -> PetState {',
          '    guard let data = try? Data(contentsOf: path),',
          '          let state = try? JSONDecoder().decode(PetState.self, from: data)',
          '    else { return PetState.initial() }',
          '    return state',
          '  }',
          '',
          '  static func save(_ state: PetState) {',
          '    guard let data = try? JSONEncoder().encode(state) else { return }',
          '    try? data.write(to: path, options: .atomic)',
          '  }',
          '}',
        ].join('\n')}
      </Card>
      <Card title="No CoreData, no SQLite" accent={ACCENT.gray}>
        <p style={{margin:0}}>A single JSON file is enough for v1. The state struct is small (~30 fields). Atomic writes prevent corruption. If the file is corrupted or missing, <code>PetState.initial()</code> starts fresh. CoreData would be overkill and harder to debug. The events JSONL is append-only and never read back after processing — it's a write buffer, not a database.</p>
      </Card>
    </div>
  ),

  build: () => (
    <div>
      <p style={{fontSize:13,color:"var(--color-text-secondary)",lineHeight:1.7,marginBottom:14}}>
        Build in this exact order. Each phase produces something you can see and feel. Don't skip ahead.
      </p>
      {[
        {phase:"Phase 1", label:"Skeleton app that stays alive", dur:"~1 day", c:ACCENT.teal, items:[
          "New Xcode project, AppKit App Delegate lifecycle",
          "LSUIElement=YES, no dock icon",
          "NSPanel floating on screen, transparent background, draggable",
          "Menubar icon with Quit button",
          "App launches, panel shows, doesn't crash — ship this to yourself",
        ]},
        {phase:"Phase 2", label:"Hooks + event watcher working", dur:"~2 days", c:ACCENT.amber, items:[
          "Write the 3 shell hook scripts (session-start, file-event, session-stop)",
          "Write git-commit.sh hook",
          "Write install-hooks.sh, test it manually",
          "Build ActivityWatcher with DispatchSource file watcher",
          "Build EventParser (JSONL → ActivityEvent)",
          "Log parsed events to console — confirm events fire when you use Claude Code",
        ]},
        {phase:"Phase 3", label:"Pet state engine", dur:"~3 days", c:ACCENT.coral, items:[
          "PetState struct + StateStore (load/save JSON)",
          "XPCalculator with all GDD rules (tiers, daily cap, diminishing returns)",
          "StreakTracker + midnight timer",
          "DecayManager (30-min timer, neglect states)",
          "PetEngine wiring ActivityWatcher → XPCalculator → StateStore",
          "Test by simulating events in the console",
        ]},
        {phase:"Phase 4", label:"Pet sprite + basic UI", dur:"~2 days", c:ACCENT.purple, items:[
          "Draw or source the pixel crab sprites (egg, kobito, kani, kamisama + idle frames)",
          "PetWidgetView — renders sprite, XP bar, mood dot",
          "Wire PetEngine @EnvironmentObject into UI",
          "Watch the XP bar tick up when you make a commit — first magic moment",
        ]},
        {phase:"Phase 5", label:"Animations + notifications", dur:"~2 days", c:ACCENT.purple, items:[
          "Idle animation loop (SwiftUI animation or HEVC video)",
          "Reaction animations (commit = claw snap, level up = flash)",
          "NotificationManager — hungry/streak/evolution notifications",
          "MoodEngine — mood score changes, visual mood indicator",
        ]},
        {phase:"Phase 6", label:"Evolution + unlockables", dur:"~3 days", c:ACCENT.amber, items:[
          "Evolution gate checker in PetEngine",
          "Evolution cutscene (full-panel animation)",
          "De-evolution logic with grace period",
          "Basic accessories system (equip/unequip)",
          "Unlock condition checker",
        ]},
        {phase:"Phase 7", label:"Polish + social", dur:"~2 days", c:ACCENT.coral, items:[
          "ShareCardView + ImageRenderer PNG export",
          "Random event system",
          "Settings panel (position, quiet hours, theme)",
          "Sparkle auto-update integration",
          "README + install docs",
          "GitHub release — ship v1.0",
        ]},
      ].map(p => (
        <div key={p.phase} style={{marginBottom:12,borderRadius:10,
          border:`1px solid ${p.c}33`,overflow:"hidden"}}>
          <div style={{padding:"8px 14px",background:p.c+"15",borderBottom:`1px solid ${p.c}33`,
            display:"flex",justifyContent:"space-between",alignItems:"center"}}>
            <div>
              <span style={{fontSize:11,fontWeight:500,color:p.c,marginRight:8}}>{p.phase}</span>
              <span style={{fontSize:13,fontWeight:500,color:"var(--color-text-primary)"}}>{p.label}</span>
            </div>
            <span style={{fontSize:11,color:"var(--color-text-tertiary)"}}>{p.dur}</span>
          </div>
          <div style={{padding:"10px 14px"}}>
            <ul style={{margin:0,paddingLeft:16,fontSize:12,color:"var(--color-text-secondary)",lineHeight:1.8}}>
              {p.items.map((item,i) => <li key={i}>{item}</li>)}
            </ul>
          </div>
        </div>
      ))}
      <Card title="Total estimate" accent={ACCENT.purple}>
        <p style={{margin:0,fontSize:13}}>~15 days of focused work to a shippable v1.0. Phase 1–3 are the hardest (unfamiliar APIs). Phase 4 is when it becomes fun. Phase 7 is when it becomes real. Build with Claude Code — the irony of your pet watching you build it is perfect.</p>
      </Card>
    </div>
  ),
};

export default function App() {
  const [active, setActive] = useState("overview");
  return (
    <div style={{fontFamily:"var(--font-sans)",maxWidth:820,margin:"0 auto",padding:"16px 0"}}>
      <div style={{marginBottom:18}}>
        <div style={{display:"flex",alignItems:"baseline",gap:10,marginBottom:3}}>
          <span style={{fontSize:21,fontWeight:500,color:"var(--color-text-primary)"}}>Kodomon</span>
          <span style={{fontSize:13,color:"var(--color-text-tertiary)"}}>Architecture Plan</span>
          <span style={{fontSize:11,padding:"2px 8px",borderRadius:20,
            background:"var(--color-background-secondary)",
            border:"1px solid var(--color-border-tertiary)",
            color:"var(--color-text-tertiary)"}}>v1.0</span>
        </div>
        <div style={{fontSize:12,color:"var(--color-text-tertiary)"}}>Swift · macOS 14+ · 100% local · MIT open source</div>
      </div>
      <div style={{display:"flex",gap:6,flexWrap:"wrap",marginBottom:18}}>
        {sections.map(s => (
          <button key={s} onClick={()=>setActive(s)} style={{
            padding:"4px 12px",borderRadius:20,fontSize:12,fontWeight:500,
            cursor:"pointer",border:"1px solid",
            borderColor:active===s?ACCENT.purple:"var(--color-border-tertiary)",
            background:active===s?ACCENT.purple+"22":"var(--color-background-secondary)",
            color:active===s?ACCENT.purple:"var(--color-text-secondary)",
            transition:"all .15s"
          }}>{nav[s]}</button>
        ))}
      </div>
      <div>{pages[active]?.()}</div>
    </div>
  );
}
