import Foundation

struct HookInstaller {
    private static let hookFiles = [
        "session-start.sh",
        "session-stop.sh",
        "file-event.sh",
        "bash-event.sh",
    ]

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

        NSLog("[Kodomon] Hooks updated from app bundle")
    }
}
