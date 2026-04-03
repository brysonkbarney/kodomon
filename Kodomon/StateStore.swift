import Foundation

class StateStore {
    static let stateURL: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".kodomon/state.json")
    }()

    static func load() -> PetState {
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder.kodomon.decode(PetState.self, from: data)
        else {
            return PetState.initial()
        }
        return state
    }

    static func save(_ state: PetState) {
        let dir = stateURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        do {
            let data = try JSONEncoder.kodomon.encode(state)
            try data.write(to: stateURL, options: .atomic)
        } catch {
            NSLog("[Kodomon] Failed to save state: %@", error.localizedDescription)
        }
    }
}

extension JSONEncoder {
    static let kodomon: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}

extension JSONDecoder {
    static let kodomon: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
