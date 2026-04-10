import SwiftUI
import AppKit

struct ShareCardView: View {
    let state: PetState

    private let cardWidth: CGFloat = 480
    private let cardHeight: CGFloat = 640

    var body: some View {
        ZStack {
            // Card background — cream
            Color(red: 0.96, green: 0.94, blue: 0.88)

            VStack(spacing: 0) {
                // Red top bar
                Color(red: 0.85, green: 0.21, blue: 0.20)
                    .frame(height: 6)

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.petName.isEmpty ? "Kodomon" : state.petName)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.16, green: 0.16, blue: 0.16))
                        Text(state.stage.displayName)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(red: 0.42, green: 0.40, blue: 0.38))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("KODOMON")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.85, green: 0.21, blue: 0.20))
                        Text("コードモン")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.85, green: 0.21, blue: 0.20).opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Sprite area with background image
                ZStack(alignment: .bottom) {
                    // Background image or dark fill
                    if let bgImage = NSImage(named: state.activeBackground) {
                        Image(nsImage: bgImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 320)
                            .clipped()
                    } else {
                        Color(red: 0.12, green: 0.10, blue: 0.16)
                            .frame(height: 320)
                    }

                    // Pet sprite
                    PixelSpriteView(
                        stage: state.stage,
                        pixelSize: 8,
                        evolveProgress: {
                            guard let next = state.stage.nextStage else { return 1.0 }
                            let current = state.stage.xpThreshold
                            let needed = next.xpThreshold - current
                            return min(max((state.totalXP - current) / needed, 0), 1.0)
                        }(),
                        petHue: state.petHue,
                        isStatic: true,
                        equippedAccessories: state.equippedAccessories
                    )
                    .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                    .padding(.bottom, 8)
                }
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)

                // Stats area
                VStack(spacing: 12) {
                    // Divider
                    Rectangle()
                        .fill(Color(red: 0.84, green: 0.82, blue: 0.77))
                        .frame(height: 1)
                        .padding(.horizontal, 8)

                    // Stats grid
                    HStack(spacing: 0) {
                        ShareStat(value: formatXP(state.totalXP), label: "XP")
                        ShareStatDivider()
                        ShareStat(value: "\(state.currentStreak)d", label: "STREAK")
                        ShareStatDivider()
                        ShareStat(value: "\(state.activeDays)", label: "ACTIVE DAYS")
                        if state.hasRevived {
                            ShareStatDivider()
                            ShareStat(value: "★", label: "SURVIVOR")
                        }
                    }

                    // Branding
                    Text("kodomon.app")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(red: 0.42, green: 0.40, blue: 0.38).opacity(0.5))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.84, green: 0.82, blue: 0.77), lineWidth: 2)
        )
    }

    private func formatXP(_ xp: Double) -> String {
        if xp >= 10000 {
            return String(format: "%.1fk", xp / 1000)
        }
        return "\(Int(xp))"
    }
}

struct ShareStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.16, green: 0.16, blue: 0.16))
            Text(label)
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(red: 0.42, green: 0.40, blue: 0.38))
        }
        .frame(maxWidth: .infinity)
    }
}

struct ShareStatDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(red: 0.84, green: 0.82, blue: 0.77))
            .frame(width: 1, height: 36)
    }
}

// MARK: - Share Card Generator

@MainActor
class ShareCardGenerator {

    static func generate(state: PetState) -> NSImage? {
        let view = ShareCardView(state: state)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        return renderer.nsImage
    }

    static func copyToClipboard(state: PetState) {
        guard let image = generate(state: state) else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        NSLog("[Kodomon] Share card copied to clipboard")
    }

    static func saveToDesktop(state: PetState) {
        guard let image = generate(state: state) else { return }
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:])
        else { return }

        let desktop = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop")
            .appendingPathComponent("Kodomon-\(state.petName).png")

        try? pngData.write(to: desktop)
        NSLog("[Kodomon] Share card saved to %@", desktop.path)
    }
}
