// TamagoCrabSprites.swift — Bridge existing SpriteData to the new SpeciesSpriteSet system
//
// The original tamago_crab sprite arrays live in SpriteData (PixelSpriteView.swift).
// This enum wraps them into a SpeciesSpriteSet for the SpriteRegistry lookup.

enum TamagoCrabSprites {
    /// Extra frames not in SpeciesSpriteSet but used by tamago_crab animations
    static var kobitoUp: [[P]] { SpriteData.kobitoUp }
    static var kobitoSquish: [[P]] { SpriteData.kobitoSquish }

    static let spriteSet = SpeciesSpriteSet(
        kobito: SpriteData.kobito,
        kobitoLeft: SpriteData.kobitoLeft,
        kobitoRight: SpriteData.kobitoRight,
        kobitoBlink: SpriteData.kobitoBlink,
        kobitoAction: SpriteData.kobitoSquish,
        kani: SpriteData.kani,
        kaniLeft: SpriteData.kaniLeft,
        kaniRight: SpriteData.kaniRight,
        kaniBlink: SpriteData.kaniBlink,
        kaniAction: SpriteData.kaniWave,
        kamisama: SpriteData.kamisama
    )
}
