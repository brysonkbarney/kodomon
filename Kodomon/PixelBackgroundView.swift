import SwiftUI

enum BackgroundTheme: String, Codable, CaseIterable {
    case tokyoNight
    case sakura
    case mountFuji
    case toriiGate

    var displayName: String {
        switch self {
        case .tokyoNight: return "Tokyo Night"
        case .sakura: return "Sakura"
        case .mountFuji: return "Mount Fuji"
        case .toriiGate: return "Torii Gate"
        }
    }
}

struct PixelBackgroundView: View {
    let theme: BackgroundTheme
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Canvas { context, size in
            let w = Int(size.width)
            let h = Int(size.height)
            switch theme {
            case .tokyoNight: drawTokyoNight(ctx: context, w: w, h: h)
            case .sakura: drawSakura(ctx: context, w: w, h: h)
            case .mountFuji: drawMountFuji(ctx: context, w: w, h: h)
            case .toriiGate: drawToriiGate(ctx: context, w: w, h: h)
            }
        }
        .frame(width: width, height: height)
    }

    // 1px drawing helpers
    private func fill(_ ctx: GraphicsContext, _ x: Int, _ y: Int, _ w: Int, _ h: Int, _ c: Color) {
        ctx.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(c))
    }

    private func dot(_ ctx: GraphicsContext, _ x: Int, _ y: Int, _ c: Color) {
        fill(ctx, x, y, 2, 2, c)
    }

    // MARK: - Tokyo Night

    private func drawTokyoNight(ctx: GraphicsContext, w: Int, h: Int) {
        // Sky
        for y in 0..<h {
            let t = Double(y) / Double(h)
            let sky = Color(red: 0.06 + t * 0.05, green: 0.04 + t * 0.04, blue: 0.16 + t * 0.06)
            fill(ctx, 0, y, w, 1, sky)
        }

        // Stars
        let starBright = Color(red: 0.92, green: 0.92, blue: 0.88)
        let starDim = Color(red: 0.55, green: 0.55, blue: 0.65)
        let stars: [(Int,Int,Bool)] = [
            (10,5,true),(30,8,false),(55,3,true),(80,10,false),(120,6,true),
            (25,15,false),(65,12,true),(95,4,false),(140,8,true),(45,2,false),
            (110,14,true),(150,7,false),(170,11,true),(15,18,false),(75,16,true),
            (135,5,false),(160,13,true),(50,20,false),(100,2,true),(185,9,false),
        ]
        for (sx, sy, bright) in stars {
            if sx < w && sy < h { dot(ctx, sx, sy, bright ? starBright : starDim) }
        }

        // Moon crescent
        let mx = w - 25
        for dy in -5...5 {
            for dx in -5...5 {
                let d1 = dx*dx + dy*dy
                let d2 = (dx-2)*(dx-2) + dy*dy
                if d1 <= 25 && d2 > 12 {
                    let x = mx + dx
                    let y = 12 + dy
                    if x >= 0 && x < w && y >= 0 && y < h {
                        dot(ctx, x, y, Color(red: 0.95, green: 0.92, blue: 0.80))
                    }
                }
            }
        }

        // Far skyline
        let farC = Color(red: 0.07, green: 0.05, blue: 0.13)
        let farBuildings: [(x:Int,w:Int,h:Int)] = [
            (0,12,30),(10,8,42),(16,14,25),(28,9,48),(35,12,32),(45,8,38),
            (51,14,28),(63,9,52),(70,12,35),(80,8,44),(86,14,30),(98,9,46),
            (105,12,36),(115,8,50),(121,14,28),(133,9,40),(140,12,34),(150,8,48),
            (156,14,26),(168,9,44),(175,12,38),(185,8,42),
        ]
        for b in farBuildings { fill(ctx, b.x, h - b.h, b.w, b.h, farC) }

        // Near buildings
        let nearC = Color(red: 0.10, green: 0.08, blue: 0.17)
        let roofC = Color(red: 0.14, green: 0.12, blue: 0.22)
        let nearBuildings: [(x:Int,w:Int,h:Int)] = [
            (4,10,45),(18,14,62),(35,10,38),(48,12,55),(65,14,68),
            (82,10,42),(95,14,58),(112,10,48),(128,14,70),(145,10,40),
            (158,12,55),(175,14,62),
        ]
        for b in nearBuildings {
            fill(ctx, b.x, h - b.h, b.w, b.h, nearC)
            fill(ctx, b.x, h - b.h, b.w, 2, roofC)
        }

        // Windows
        let wColors = [
            Color(red: 0.95, green: 0.82, blue: 0.35),
            Color(red: 0.90, green: 0.70, blue: 0.30),
            Color(red: 0.35, green: 0.75, blue: 0.85),
            Color(red: 0.08, green: 0.06, blue: 0.14),
            Color(red: 0.08, green: 0.06, blue: 0.14),
        ]
        for b in nearBuildings {
            for y in stride(from: h - b.h + 4, to: h - 2, by: 5) {
                for x in stride(from: b.x + 2, to: b.x + b.w - 2, by: 4) {
                    if x < w && y < h {
                        let ci = ((x * 7 + y * 13) % wColors.count + wColors.count) % wColors.count
                        fill(ctx, x, y, 2, 3, wColors[ci])
                    }
                }
            }
        }

        // Neon
        let neonPink = Color(red: 0.95, green: 0.25, blue: 0.45)
        let neonBlue = Color(red: 0.30, green: 0.50, blue: 0.95)
        fill(ctx, 58, h - 40, 8, 3, neonPink)
        fill(ctx, 125, h - 50, 6, 3, neonBlue)
        fill(ctx, 90, h - 55, 10, 3, neonPink)
    }

    // MARK: - Sakura

    private func drawSakura(ctx: GraphicsContext, w: Int, h: Int) {
        // Sky
        for y in 0..<h {
            let t = Double(y) / Double(h)
            let sky = Color(red: 0.95 + t * 0.02, green: 0.83 + t * 0.07, blue: 0.87 + t * 0.03)
            fill(ctx, 0, y, w, 1, sky)
        }

        // Grass
        let grassY = h - 16
        for y in grassY..<h {
            let g = y % 2 == 0 ? Color(red: 0.58, green: 0.72, blue: 0.45) : Color(red: 0.52, green: 0.66, blue: 0.40)
            fill(ctx, 0, y, w, 1, g)
        }

        // Path
        let pathC = Color(red: 0.78, green: 0.72, blue: 0.62)
        for y in grassY..<h {
            let halfW = 15 + (h - y) * 3
            fill(ctx, w/2 - halfW, y, halfW * 2, 1, pathC)
        }

        // Main tree trunk
        let trunk = Color(red: 0.30, green: 0.18, blue: 0.12)
        let tX = 30
        fill(ctx, tX, 35, 4, grassY - 35, trunk)
        fill(ctx, tX - 1, grassY - 4, 6, 4, trunk) // base

        // Branches — drawn as lines
        let branchC = Color(red: 0.36, green: 0.22, blue: 0.14)
        // Right branches
        for i in 0..<30 { fill(ctx, tX + 4 + i, 45 - i/3, 2, 2, branchC) }
        for i in 0..<22 { fill(ctx, tX + 4 + i, 60 - i/4, 2, 2, branchC) }
        for i in 0..<18 { fill(ctx, tX + 4 + i, 75 - i/4, 2, 2, branchC) }
        // Left branches
        for i in 0..<16 { fill(ctx, tX - 2 - i, 40 - i/3, 2, 2, branchC) }
        for i in 0..<12 { fill(ctx, tX - 2 - i, 55 - i/4, 2, 2, branchC) }

        // Blossom clusters — circles
        let b1 = Color(red: 0.96, green: 0.68, blue: 0.73)
        let b2 = Color(red: 0.94, green: 0.56, blue: 0.64)
        let b3 = Color(red: 0.98, green: 0.78, blue: 0.82)
        let bc = [b1, b2, b3]

        let clusters: [(cx:Int, cy:Int, r:Int)] = [
            (55, 32, 12), (45, 24, 10), (65, 40, 10),
            (38, 38, 8), (70, 30, 8),
            (18, 28, 10), (10, 34, 8), (22, 42, 7),
            (50, 50, 8), (60, 55, 7),
            (40, 60, 7), (52, 65, 6),
        ]
        for cl in clusters {
            for dy in -cl.r...cl.r {
                for dx in -cl.r...cl.r {
                    if dx*dx + dy*dy <= cl.r*cl.r {
                        let x = cl.cx + dx
                        let y = cl.cy + dy
                        if x >= 0 && x < w && y >= 0 && y < h {
                            let ci = ((x*3 + y*7) % bc.count + bc.count) % bc.count
                            dot(ctx, x, y, bc[ci])
                        }
                    }
                }
            }
        }

        // Far tree (right)
        let t2x = w - 35
        fill(ctx, t2x, 55, 3, grassY - 55, trunk.opacity(0.5))
        let farClusters: [(cx:Int,cy:Int,r:Int)] = [(t2x+8,46,8),(t2x-4,42,7),(t2x+3,52,6)]
        for cl in farClusters {
            for dy in -cl.r...cl.r {
                for dx in -cl.r...cl.r {
                    if dx*dx + dy*dy <= cl.r*cl.r {
                        let x = cl.cx + dx; let y = cl.cy + dy
                        if x >= 0 && x < w && y >= 0 && y < h { dot(ctx, x, y, b3.opacity(0.6)) }
                    }
                }
            }
        }

        // Falling petals
        let petal = Color(red: 0.96, green: 0.72, blue: 0.77)
        let petals: [(Int,Int)] = [
            (85,20),(100,35),(120,15),(140,45),(155,25),(170,50),
            (90,60),(110,70),(80,80),(130,65),(150,75),(175,30),
            (95,10),(125,55),(145,85),(105,90),(82,50),(185,60),
        ]
        for (px2, py) in petals {
            if px2 < w && py < h { dot(ctx, px2, py, petal) }
        }
    }

    // MARK: - Mount Fuji

    private func drawMountFuji(ctx: GraphicsContext, w: Int, h: Int) {
        // Sky — dawn gradient
        for y in 0..<h {
            let t = Double(y) / Double(h)
            let sky = Color(
                red: 0.60 + t * 0.20,
                green: 0.68 + t * 0.12,
                blue: 0.90 - t * 0.15
            )
            fill(ctx, 0, y, w, 1, sky)
        }

        // Distant mountain range
        let distC = Color(red: 0.58, green: 0.60, blue: 0.75)
        for x in 0..<w {
            let peakY = Int(sin(Double(x) * 0.03) * 10 + sin(Double(x) * 0.07) * 5 + Double(h) * 0.55)
            fill(ctx, x, peakY, 1, h - peakY, distC.opacity(0.4))
        }

        // Mount Fuji — concave slopes (the key difference!)
        let fujiPeak = Int(Double(h) * 0.10)
        let fujiBase = h - 25
        let fujiCenter = w / 2
        let mtnColor = Color(red: 0.28, green: 0.30, blue: 0.48)
        let mtnShadow = Color(red: 0.22, green: 0.24, blue: 0.40)
        let snow = Color(red: 0.96, green: 0.97, blue: 0.99)
        let snowShade = Color(red: 0.84, green: 0.86, blue: 0.92)

        for y in fujiPeak..<fujiBase {
            let t = Double(y - fujiPeak) / Double(fujiBase - fujiPeak)
            // Concave slope — sqrt gives the classic Fuji profile
            let spread = sqrt(t) * Double(w) * 0.48
            let left = fujiCenter - Int(spread)
            let right = fujiCenter + Int(spread)
            for x in max(0, left)...min(w - 1, right) {
                let isLeft = x < fujiCenter
                fill(ctx, x, y, 1, 1, isLeft ? mtnShadow : mtnColor)
            }
        }

        // Snow cap
        let snowDepth = Int(Double(fujiBase - fujiPeak) * 0.18)
        for y in fujiPeak..<(fujiPeak + snowDepth) {
            let t = Double(y - fujiPeak) / Double(fujiBase - fujiPeak)
            let spread = sqrt(t) * Double(w) * 0.48
            // Snow tapers with jagged edge
            let snowSpread = spread * (1.0 - Double(y - fujiPeak) / Double(snowDepth) * 0.6)
            let left = fujiCenter - Int(snowSpread)
            let right = fujiCenter + Int(snowSpread)
            for x in max(0, left)...min(w - 1, right) {
                let isLeft = x < fujiCenter
                fill(ctx, x, y, 1, 1, isLeft ? snowShade : snow)
            }
        }
        // Jagged snow drip edge
        for x in (fujiCenter - 25)...(fujiCenter + 25) {
            let jag = ((x * 7 + 3) % 5) - 1
            let y = fujiPeak + snowDepth + jag
            if x >= 0 && x < w && y >= 0 && y < h {
                fill(ctx, x, y, 1, 2, snow.opacity(0.5))
            }
        }

        // Clouds
        let cloudC = Color(red: 0.97, green: 0.97, blue: 0.99)
        let cloudS = Color(red: 0.86, green: 0.88, blue: 0.93)
        let clouds: [(x:Int,y:Int,w:Int)] = [(15,35,24),(130,28,20),(75,40,16)]
        for c in clouds {
            fill(ctx, c.x, c.y, c.w, 4, cloudC)
            fill(ctx, c.x + 3, c.y - 2, c.w - 6, 3, cloudC)
            fill(ctx, c.x + 2, c.y + 4, c.w - 4, 2, cloudS)
        }

        // Lake
        let lakeY = h - 20
        let lake = Color(red: 0.42, green: 0.58, blue: 0.75)
        let lakeShimmer = Color(red: 0.52, green: 0.68, blue: 0.82)
        for y in lakeY..<(h - 8) {
            for x in 0..<w {
                let shimmer = (x + y * 3) % 11 == 0
                fill(ctx, x, y, 1, 1, shimmer ? lakeShimmer : lake)
            }
        }

        // Shore grass
        let grass = Color(red: 0.45, green: 0.60, blue: 0.35)
        let grassD = Color(red: 0.38, green: 0.52, blue: 0.30)
        for y in (h - 8)..<h {
            for x in 0..<w {
                fill(ctx, x, y, 1, 1, (x + y) % 3 == 0 ? grassD : grass)
            }
        }
    }

    // MARK: - Torii Gate

    private func drawToriiGate(ctx: GraphicsContext, w: Int, h: Int) {
        // Sunset sky
        for y in 0..<h {
            let t = Double(y) / Double(h)
            let sky: Color
            if t < 0.3 {
                sky = Color(red: 0.95, green: 0.50 + t * 1.2, blue: 0.25 + t * 0.8)
            } else if t < 0.6 {
                sky = Color(red: 0.96, green: 0.78, blue: 0.52)
            } else {
                let f = (t - 0.6) / 0.4
                sky = Color(red: 0.90 - f * 0.25, green: 0.72 - f * 0.15, blue: 0.50 + f * 0.05)
            }
            fill(ctx, 0, y, w, 1, sky)
        }

        // Sun
        let sunX = w / 2
        let sunY = 28
        let sunOuter = Color(red: 0.98, green: 0.86, blue: 0.55)
        let sunInner = Color(red: 0.99, green: 0.93, blue: 0.72)
        for dy in -12...12 {
            for dx in -12...12 {
                let d = dx*dx + dy*dy
                if d <= 144 {
                    let x = sunX + dx; let y = sunY + dy
                    if x >= 0 && x < w && y >= 0 && y < h {
                        fill(ctx, x, y, 1, 1, d <= 64 ? sunInner : sunOuter)
                    }
                }
            }
        }

        // Ground
        let groundY = h - 18
        let ground = Color(red: 0.52, green: 0.47, blue: 0.40)
        let groundL = Color(red: 0.60, green: 0.55, blue: 0.47)
        for y in groundY..<h {
            for x in 0..<w { fill(ctx, x, y, 1, 1, (x + y) % 5 == 0 ? groundL : ground) }
        }

        // Stone path
        let pathC = Color(red: 0.72, green: 0.67, blue: 0.57)
        for y in groundY..<h {
            let halfW = 12 + (h - y) * 2
            fill(ctx, w/2 - halfW, y, halfW * 2, 1, pathC)
        }

        // Steps on path
        let stepC = Color(red: 0.65, green: 0.60, blue: 0.50)
        for y in stride(from: groundY, to: h, by: 4) {
            let halfW = 12 + (h - y) * 2
            fill(ctx, w/2 - halfW, y, halfW * 2, 1, stepC)
        }

        // Torii gate
        let torii = Color(red: 0.82, green: 0.18, blue: 0.16)
        let toriiD = Color(red: 0.65, green: 0.12, blue: 0.12)
        let toriiL = Color(red: 0.92, green: 0.28, blue: 0.24)
        let cx = w / 2
        let pL = cx - 24
        let pR = cx + 22
        let gTop = groundY - 50

        // Pillars
        fill(ctx, pL, gTop + 8, 4, groundY - gTop - 8, torii)
        fill(ctx, pL + 4, gTop + 8, 1, groundY - gTop - 8, toriiD) // shadow edge
        fill(ctx, pR, gTop + 8, 4, groundY - gTop - 8, torii)
        fill(ctx, pR + 4, gTop + 8, 1, groundY - gTop - 8, toriiD)

        // Top beam (kasagi) — thick, extends past pillars
        fill(ctx, pL - 8, gTop, pR - pL + 20, 4, torii)
        fill(ctx, pL - 8, gTop + 4, pR - pL + 20, 2, toriiD)
        // Curved tips
        fill(ctx, pL - 10, gTop - 2, 4, 3, torii)
        fill(ctx, pR + 14, gTop - 2, 4, 3, torii)
        fill(ctx, pL - 12, gTop - 4, 3, 3, toriiL)
        fill(ctx, pR + 16, gTop - 4, 3, 3, toriiL)

        // Second beam (nuki)
        fill(ctx, pL, gTop + 14, pR - pL + 4, 3, torii)

        // Center tablet
        fill(ctx, cx - 5, gTop + 9, 12, 7, toriiD)
        fill(ctx, cx - 4, gTop + 10, 10, 5, Color(red: 0.15, green: 0.10, blue: 0.08))

        // Trees
        let treeD = Color(red: 0.18, green: 0.26, blue: 0.15)
        let treeM = Color(red: 0.22, green: 0.32, blue: 0.20)
        let treeTrunk = Color(red: 0.28, green: 0.18, blue: 0.12)

        let trees: [(x:Int,h:Int,r:Int)] = [
            (8, 35, 10), (20, 28, 8), (2, 22, 7),
            (w - 12, 32, 9), (w - 25, 25, 8), (w - 5, 20, 6),
        ]
        for t in trees {
            fill(ctx, t.x, groundY - t.h, 2, t.h, treeTrunk)
            for dy in -t.r...0 {
                let rw = t.r - abs(dy) / 2
                for dx in -rw...rw {
                    let x = t.x + dx; let y = groundY - t.h + dy
                    if x >= 0 && x < w && y >= 0 && y < h {
                        fill(ctx, x, y, 1, 1, (x + y) % 3 == 0 ? treeM : treeD)
                    }
                }
            }
        }
    }
}
