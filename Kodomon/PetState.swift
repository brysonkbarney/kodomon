//
//  PetState.swift
//  Kodomon
//
//  Legacy file name retained — this file used to hold the flat `PetState`
//  struct. As of v2, state is split into `PlayerState` + `[KodomonState]`;
//  this file now holds only the shared `Stage` and `NeglectState` enums.
//  See PlayerState.swift and KodomonState.swift for the canonical types.
//
//  Stage XP thresholds and de-evolution floors moved to `Rarity` (in
//  SpeciesCatalog.swift) because rarer species scale their XP gates up.
//  Callers should use `kodomon.rarity.xpThreshold(for:)` instead.
//

import Foundation

enum Stage: String, Codable, CaseIterable {
    case tamago = "tamago"
    case kobito = "kobito"
    case kani = "kani"
    case kamisama = "kamisama"

    var displayName: String {
        switch self {
        case .tamago: return "Tamago 卵"
        case .kobito: return "Kobito 小人"
        case .kani: return "Kani 蟹"
        case .kamisama: return "Kamisama 神様"
        }
    }

    /// Active days required to evolve INTO this stage. Shared across all
    /// species — only XP gates scale by rarity.
    var requiredActiveDays: Int {
        switch self {
        case .tamago: return 0
        case .kobito: return 2
        case .kani: return 5
        case .kamisama: return 14
        }
    }

    /// Streak required to evolve INTO this stage. Shared across all species.
    var requiredStreak: Int {
        switch self {
        case .tamago: return 0
        case .kobito: return 2
        case .kani: return 5
        case .kamisama: return 10
        }
    }

    var nextStage: Stage? {
        switch self {
        case .tamago: return .kobito
        case .kobito: return .kani
        case .kani: return .kamisama
        case .kamisama: return nil
        }
    }

    var previousStage: Stage? {
        switch self {
        case .tamago: return nil
        case .kobito: return .tamago
        case .kani: return .kobito
        case .kamisama: return .kani
        }
    }
}

enum NeglectState: String, Codable {
    case none
    case tired     // 8h no activity
    case sad       // 1 missed day
    case sick      // 2-4 missed days
    case critical  // 5-6 missed days
    case ranAway   // 7+ missed days
}
