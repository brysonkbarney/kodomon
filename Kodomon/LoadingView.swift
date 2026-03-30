import SwiftUI

struct LoadingView: View {
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.96, green: 0.94, blue: 0.88))

            VStack(spacing: 20) {
                Spacer()

                // Spinning pixel squares
                ZStack {
                    ForEach(0..<4, id: \.self) { i in
                        Rectangle()
                            .fill(Color(red: 0.85, green: 0.21, blue: 0.20))
                            .frame(width: 8, height: 8)
                            .offset(x: 14)
                            .rotationEffect(.degrees(Double(i) * 90 + rotation))
                    }
                }
                .frame(width: 40, height: 40)

                Text("Incubating...")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(red: 0.42, green: 0.40, blue: 0.38))

                Spacer()
            }
            .opacity(opacity)
        }
        .frame(width: 240, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) { opacity = 1 }
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
