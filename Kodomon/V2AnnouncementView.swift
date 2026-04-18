import SwiftUI

/// One-time announcement modal shown to existing users after upgrading to
/// v1.1.0 — introduces the Kodex / collection system with Pokemon-style
/// typewriter text on a Japanese scroll backdrop.
struct V2AnnouncementView: View {
    var onDismiss: () -> Void

    @State private var page: Int = 0
    @State private var displayedText: String = ""
    @State private var isTyping: Bool = false

    private var buttonLabel: String {
        if isTyping { return "Skip" }
        return page < pages.count - 1 ? "Next \u{25B6}" : "Let's go!"
    }

    private let pages: [(title: String, body: String)] = [
        (
            "「ようこそ！」 Kodex",
            "5 new Kodomon are hiding in your codebase."
        ),
        (
            "「たまご」 Eggs",
            "Keep coding to draw them out. Eggs appear, incubate, then hatch."
        ),
        (
            "「しゅつじん」 Deploy",
            "Swap your active Kodomon anytime. Each one grows in its own time."
        )
    ]

    var body: some View {
        scrollPanel
            .frame(width: 220)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var scrollPanel: some View {
        VStack(spacing: 0) {
            // Top rod (scroll handle)
            scrollRod

            // Parchment body
            VStack(alignment: .leading, spacing: 10) {
                // Title line
                Text(pages[page].title)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(KodomonColors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Typewriter body
                Text(displayedText)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(KodomonColors.textPrimary)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
                    .fixedSize(horizontal: false, vertical: true)

                // Progress dots
                HStack(spacing: 4) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle()
                            .fill(i == page ? KodomonColors.accent : KodomonColors.border)
                            .frame(width: 4, height: 4)
                    }
                    Spacer()
                    Text("\(page + 1)/\(pages.count)")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(KodomonColors.textSecondary)
                }

                // Actions
                Button(action: {
                    if isTyping {
                        finishTyping()
                    } else if page < pages.count - 1 {
                        advance()
                    } else {
                        onDismiss()
                    }
                }) {
                    Text(buttonLabel)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(KodomonColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(KodomonColors.background)

            // Bottom rod
            scrollRod
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(color: .black.opacity(0.5), radius: 14, x: 0, y: 6)
        .onAppear {
            startTyping(pages[0].body)
        }
    }

    /// Decorative top/bottom rod (bamboo scroll handle look).
    private var scrollRod: some View {
        ZStack {
            Rectangle()
                .fill(KodomonColors.accent)
                .frame(height: 10)
            Rectangle()
                .fill(Color.black.opacity(0.25))
                .frame(height: 1)
                .offset(y: 3)
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
                .offset(y: -3)
        }
    }

    // MARK: - Typewriter

    private func advance() {
        if isTyping {
            finishTyping()
            return
        }
        let next = page + 1
        guard next < pages.count else { return }
        page = next
        startTyping(pages[next].body)
    }

    private func startTyping(_ full: String) {
        isTyping = true
        displayedText = ""
        let chars = Array(full)
        typeNextChar(chars: chars, index: 0)
    }

    private func typeNextChar(chars: [Character], index: Int) {
        guard isTyping else { return }
        guard index < chars.count else {
            isTyping = false
            return
        }
        displayedText.append(chars[index])
        let delay: Double = (chars[index] == " ") ? 0.012 : 0.022
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            typeNextChar(chars: chars, index: index + 1)
        }
    }

    private func finishTyping() {
        isTyping = false
        displayedText = pages[page].body
    }
}
