import Foundation

enum ActivityEvent {
    case sessionStart(sessionId: String, cwd: String, timestamp: Date)
    case sessionStop(sessionId: String, timestamp: Date)
    case fileWrite(filePath: String, linesWritten: Int, timestamp: Date)
    case gitCommit(linesAdded: Int, linesRemoved: Int, filesChanged: Int, timestamp: Date)
}

struct RawEvent: Codable {
    let type: String
    let ts: TimeInterval
    let session_id: String?
    let cwd: String?
    let file: String?
    let lines: Int?
    let hash: String?
    let lines_added: Int?
    let lines_removed: Int?
    let files: Int?
}

extension RawEvent {
    func toActivityEvent() -> ActivityEvent? {
        let date = Date(timeIntervalSince1970: ts)

        switch type {
        case "session_start":
            return .sessionStart(
                sessionId: session_id ?? "unknown",
                cwd: cwd ?? "unknown",
                timestamp: date
            )
        case "session_stop":
            return .sessionStop(
                sessionId: session_id ?? "unknown",
                timestamp: date
            )
        case "file_write":
            return .fileWrite(
                filePath: file ?? "unknown",
                linesWritten: lines ?? 0,
                timestamp: date
            )
        case "git_commit":
            return .gitCommit(
                linesAdded: lines_added ?? 0,
                linesRemoved: lines_removed ?? 0,
                filesChanged: files ?? 0,
                timestamp: date
            )
        default:
            NSLog("[Kodomon] Unknown event type: %@", type)
            return nil
        }
    }
}
