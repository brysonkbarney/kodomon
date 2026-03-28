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

        guard let data = try? JSONEncoder.kodomon.encode(state) else { return }
        try? data.write(to: stateURL, options: .atomic)
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
