import Foundation

struct HookInstaller {
    private static let hookFiles = [
        "session-start.sh",
        "session-stop.sh",
        "file-event.sh",
        "bash-event.sh",
    ]

    private static let kodomonCommandPrefix = "~/.kodomon/hooks/"

    static func installOrUpdate() {
        let fm = FileManager.default
        let hooksDir = fm.homeDirectoryForCurrentUser
            .appendingPathComponent(".kodomon/hooks")
        let eventFile = fm.homeDirectoryForCurrentUser
            .appendingPathComponent(".kodomon/events.jsonl")

        try? fm.createDirectory(at: hooksDir, withIntermediateDirectories: true)

        for name in hookFiles {
            guard let bundled = Bundle.main.url(forResource: name, withExtension: nil) else {
                NSLog("[Kodomon] Hook %@ not found in bundle", name)
                continue
            }
            let dest = hooksDir.appendingPathComponent(name)
            try? fm.removeItem(at: dest)
            try? fm.copyItem(at: bundled, to: dest)
            chmod(dest.path, 0o755)
        }

        // Ensure events file exists
        if !fm.fileExists(atPath: eventFile.path) {
            fm.createFile(atPath: eventFile.path, contents: nil)
        }

        installOrUpdateCodexHooks()

        NSLog("[Kodomon] Hooks updated from app bundle")
    }

    /// Self-heal `~/.codex/hooks.json` on every launch so Sparkle-updated
    /// users get Codex hook wiring without re-running the curl installer.
    /// Idempotent — re-running produces the same merged file, and any
    /// non-Kodomon entries the user added are preserved.
    private static func installOrUpdateCodexHooks() {
        let fm = FileManager.default
        let codexDir = fm.homeDirectoryForCurrentUser.appendingPathComponent(".codex")
        let hooksFile = codexDir.appendingPathComponent("hooks.json")

        try? fm.createDirectory(at: codexDir, withIntermediateDirectories: true)

        var rootDict: [String: Any] = [:]
        var hooksDict: [String: [[String: Any]]] = [
            "SessionStart": [],
            "PostToolUse": [],
            "Stop": [],
        ]

        if let data = try? Data(contentsOf: hooksFile),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            rootDict = parsed
            if let existingHooks = parsed["hooks"] as? [String: Any] {
                for key in hooksDict.keys {
                    if let arr = existingHooks[key] as? [[String: Any]] {
                        hooksDict[key] = stripKodomonEntries(arr)
                    }
                }
            }
        }

        for (key, entries) in kodomonCodexEntries() {
            hooksDict[key, default: []].append(contentsOf: entries)
        }

        rootDict["hooks"] = hooksDict

        do {
            let data = try JSONSerialization.data(
                withJSONObject: rootDict,
                options: [.prettyPrinted, .sortedKeys]
            )
            try data.write(to: hooksFile, options: .atomic)
        } catch {
            NSLog("[Kodomon] Failed to write Codex hooks: %@", error.localizedDescription)
        }
    }

    private static func stripKodomonEntries(_ entries: [[String: Any]]) -> [[String: Any]] {
        entries.filter { entry in
            guard let nested = entry["hooks"] as? [[String: Any]] else { return true }
            return !nested.contains { hook in
                (hook["command"] as? String)?.contains("kodomon") == true
            }
        }
    }

    private static func kodomonCodexEntries() -> [String: [[String: Any]]] {
        let runScript: (String) -> [String: Any] = { script in
            ["hooks": [["type": "command", "command": kodomonCommandPrefix + script]]]
        }
        let runScriptForMatcher: (String, String) -> [String: Any] = { matcher, script in
            ["matcher": matcher,
             "hooks": [["type": "command", "command": kodomonCommandPrefix + script]]]
        }
        return [
            "SessionStart": [runScript("session-start.sh")],
            "PostToolUse": [
                runScriptForMatcher("Edit|Write|apply_patch", "file-event.sh"),
                runScriptForMatcher("Bash", "bash-event.sh"),
            ],
            "Stop": [runScript("session-stop.sh")],
        ]
    }
}
