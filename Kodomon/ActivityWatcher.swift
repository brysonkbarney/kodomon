import Foundation
import Combine

nonisolated(unsafe) let kodomonEventsPath: String = {
    FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".kodomon/events.jsonl").path
}()

@MainActor
class ActivityWatcher: ObservableObject {
    private var fileDescriptor: Int32 = -1
    private var source: DispatchSourceFileSystemObject?
    private var lastReadOffset: UInt64 = 0
    private var lineBuffer: String = ""
    private var isReading = false

    let eventPublisher = PassthroughSubject<ActivityEvent, Never>()

    func startWatching() {
        let path = kodomonEventsPath

        // Create events file if it doesn't exist
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".kodomon")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil)
        }

        NSLog("[Kodomon] Events file: %@", path)

        // Read any existing events first
        readNewLines()

        // Watch for changes
        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            NSLog("[Kodomon] Failed to open events file")
            return
        }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: .main
        )

        source?.setEventHandler { [weak self] in
            self?.readNewLines()
        }

        source?.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
            }
        }

        source?.resume()
        NSLog("[Kodomon] Watching for events")
    }

    func stopWatching() {
        source?.cancel()
        source = nil
    }

    func resetOffset() {
        lastReadOffset = 0
        lineBuffer = ""
    }

    private func readNewLines() {
        guard !isReading else { return }
        isReading = true
        defer { isReading = false }
        let path = kodomonEventsPath
        guard let fileHandle = FileHandle(forReadingAtPath: path) else {
            NSLog("[Kodomon] Cannot open events file for reading")
            return
        }
        defer { fileHandle.closeFile() }

        fileHandle.seek(toFileOffset: lastReadOffset)
        let newData = fileHandle.readDataToEndOfFile()

        guard !newData.isEmpty else { return }
        lastReadOffset += UInt64(newData.count)

        guard let newText = String(data: newData, encoding: .utf8) else { return }

        lineBuffer += newText
        let lines = lineBuffer.components(separatedBy: "\n")
        lineBuffer = lines.last ?? ""

        let decoder = JSONDecoder()

        for line in lines.dropLast() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            guard let data = trimmed.data(using: .utf8) else { continue }

            do {
                let raw = try decoder.decode(RawEvent.self, from: data)
                if let event = raw.toActivityEvent() {
                    eventPublisher.send(event)
                    NSLog("[Kodomon] Event: %@", raw.type)
                }
            } catch {
                NSLog("[Kodomon] Parse error: %@", error.localizedDescription)
            }
        }
    }

    deinit {
        source?.cancel()
    }
}
