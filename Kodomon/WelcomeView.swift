import SwiftUI

// Colors
private let cream = Color(red: 0.96, green: 0.94, blue: 0.88)
private let red = Color(red: 0.85, green: 0.21, blue: 0.20)
private let dark = Color(red: 0.16, green: 0.16, blue: 0.16)
private let grey = Color(red: 0.42, green: 0.40, blue: 0.38)
private let borderC = Color(red: 0.84, green: 0.82, blue: 0.77)

struct WelcomeView: View {
    @State private var page: Int = 0
    let onConfirm: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            red.frame(height: 4)

            if page == 0 {
                WelcomePage { page = 1 }
                    .transition(.opacity)
            } else if page == 1 {
                HowItWorksPage { page = 2 }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                NamePage(onConfirm: onConfirm)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .background(cream)
        .frame(width: 340, height: 440)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
        .animation(.easeInOut(duration: 0.3), value: page)
    }
}

// MARK: - Page 1: Welcome

struct WelcomePage: View {
    let onStart: () -> Void

    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var eggBob: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)

            // Title
            Text("Welcome to")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(grey)
                .opacity(titleOpacity)

            Text("KODOMON")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(dark)
                .opacity(titleOpacity)

            Text("コードモン")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(red)
                .opacity(subtitleOpacity)
                .padding(.top, 2)

            Spacer()

            // Egg waiting to be named
            PixelSpriteView(stage: .tamago, pixelSize: 4)
                .offset(y: eggBob)

            Spacer()

            // Start button
            Button(action: onStart) {
                Text("Start")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 60)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(red)
                    )
            }
            .buttonStyle(.plain)
            .opacity(buttonOpacity)

            Spacer().frame(height: 30)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { titleOpacity = 1 }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) { subtitleOpacity = 1 }
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) { buttonOpacity = 1 }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { eggBob = -5 }
        }
    }
}

// MARK: - Page 2: How It Works

struct HowItWorksPage: View {
    let onNext: () -> Void
    @State private var opacity: Double = 0

    private let bullets: [(icon: String, text: String)] = [
        ("▲", "Code with Claude to earn XP and streaks"),
        ("★", "Help your Kodomon evolve"),
        ("◆", "Work together to unlock new rewards"),
        ("✦", "Stop coding and your Kodomon gets sad"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            Text("How It Works")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(dark)

            Spacer().frame(height: 24)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(0..<bullets.count, id: \.self) { i in
                    HStack(alignment: .top, spacing: 10) {
                        Text(bullets[i].icon)
                            .font(.system(size: 12))
                            .foregroundColor(red)
                            .frame(width: 16)
                        Text(bullets[i].text)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(dark)
                    }
                }
            }
            .padding(.horizontal, 30)

            Spacer().frame(height: 16)

            // Evolution preview — silhouettes
            HStack(spacing: 14) {
                VStack(spacing: 4) {
                    PixelSpriteView(stage: .tamago, pixelSize: 2, isStatic: true)
                    Text("Egg")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(grey)
                }
                Text("→").foregroundColor(grey)
                VStack(spacing: 4) {
                    PixelSpriteView(stage: .kobito, pixelSize: 2, isStatic: true)
                        .colorMultiply(.black).opacity(0.3)
                    Text("???")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(grey)
                }
                Text("→").foregroundColor(grey)
                VStack(spacing: 4) {
                    PixelSpriteView(stage: .kani, pixelSize: 2, isStatic: true)
                        .colorMultiply(.black).opacity(0.3)
                    Text("???")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(grey)
                }
                Text("→").foregroundColor(grey)
                VStack(spacing: 4) {
                    PixelSpriteView(stage: .kamisama, pixelSize: 1.5, isStatic: true)
                        .colorMultiply(.black).opacity(0.3)
                    Text("???")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(grey)
                }
            }

            Spacer()

            Text("Tap ≡ on the card anytime for stats and tips")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(grey)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 8)

            Button(action: onNext) {
                Text("Got it!")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(red)
                    )
            }
            .buttonStyle(.plain)

            Spacer().frame(height: 24)
        }
        .padding(.horizontal, 16)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { opacity = 1 }
        }
    }
}

// MARK: - Page 3: Name picker

struct NamePage: View {
    @State private var options: [String] = NameGenerator.randomThree()
    @State private var selectedName: String = ""
    @State private var customText: String = ""
    @State private var excluded: [String] = []
    @State private var eggBob: CGFloat = 0
    @FocusState private var textFieldFocused: Bool

    let onConfirm: (String) -> Void

    var body: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 12)

            Text("Name Your Kodomon")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(dark)

            // Egg sprite
            PixelSpriteView(stage: .tamago, pixelSize: 3)
                .offset(y: eggBob)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        eggBob = -4
                    }
                }

            // Three name buttons
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { name in
                    Button(action: {
                        selectedName = name
                        customText = name
                    }) {
                        Text(name)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(selectedName == name ? .white : dark)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedName == name ? red : borderC.opacity(0.5))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Reroll
            Button(action: {
                excluded.append(contentsOf: options)
                options = NameGenerator.reroll(excluding: excluded)
                selectedName = ""
            }) {
                Text("↻ More names")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(grey)
            }
            .buttonStyle(.plain)

            Spacer().frame(height: 4)

            // Confirm — disabled until a name is selected
            Button(action: {
                guard !selectedName.isEmpty else { return }
                onConfirm(selectedName)
            }) {
                Text("Let's go!")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectedName.isEmpty ? grey : red)
                    )
            }
            .buttonStyle(.plain)
            .disabled(selectedName.isEmpty)

            Spacer().frame(height: 16)
        }
        .padding(.horizontal, 16)
        .onAppear {
            selectedName = options[0]
            customText = options[0]
        }
    }
}
