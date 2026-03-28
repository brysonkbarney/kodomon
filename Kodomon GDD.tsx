import { useState } from "react";

const sections = ["overview", "xp", "evolution", "decay", "mood", "events", "unlockables", "timeline", "social"];

const nav = {
  overview: "Overview",
  xp: "XP System",
  evolution: "Evolution Gates",
  decay: "Decay & Neglect",
  mood: "Mood System",
  events: "Random Events",
  unlockables: "Unlockables",
  social: "Social & Notifications",
};

const pill = (label, color) => (
  <span style={{
    display:"inline-block", padding:"2px 10px", borderRadius:20,
    fontSize:11, fontWeight:500, marginRight:6, marginBottom:4,
    background: color + "22", color, border:`1px solid ${color}55`
  }}>{label}</span>
);

const Tag = ({children, c="#7F77DD"}) => pill(children, c);

const Card = ({title, children, accent="#7F77DD"}) => (
  <div style={{
    borderRadius:12, border:"1px solid var(--color-border-tertiary)",
    background:"var(--color-background-secondary)", marginBottom:16, overflow:"hidden"
  }}>
    <div style={{padding:"10px 16px", borderBottom:"1px solid var(--color-border-tertiary)",
      borderLeft:`3px solid ${accent}`, fontSize:13, fontWeight:500,
      color:"var(--color-text-primary)"}}>{title}</div>
    <div style={{padding:"12px 16px", fontSize:13, color:"var(--color-text-secondary)", lineHeight:1.7}}>{children}</div>
  </div>
);

const Table = ({heads, rows, accents=[]}) => (
  <table style={{width:"100%", borderCollapse:"collapse", fontSize:12, marginBottom:8}}>
    <thead>
      <tr>{heads.map((h,i) => <th key={i} style={{textAlign:"left", padding:"6px 10px",
        borderBottom:"1px solid var(--color-border-tertiary)", color:"var(--color-text-secondary)",
        fontWeight:500}}>{h}</th>)}</tr>
    </thead>
    <tbody>
      {rows.map((r,i) => (
        <tr key={i} style={{background: i%2===0?"transparent":"var(--color-background-tertiary)"}}>
          {r.map((c,j) => <td key={j} style={{padding:"7px 10px",
            borderBottom:"1px solid var(--color-border-tertiary)",
            color: j===0 ? (accents[i]||"var(--color-text-primary)") : "var(--color-text-secondary)",
            fontWeight: j===0?500:400}}>{c}</td>)}
        </tr>
      ))}
    </tbody>
  </table>
);

const Stat = ({label, value, sub, color="#7F77DD"}) => (
  <div style={{flex:1, minWidth:120, padding:"12px 14px", borderRadius:10,
    border:"1px solid var(--color-border-tertiary)",
    background:"var(--color-background-secondary)", textAlign:"center"}}>
    <div style={{fontSize:22, fontWeight:500, color}}>{value}</div>
    <div style={{fontSize:12, fontWeight:500, color:"var(--color-text-primary)", marginTop:2}}>{label}</div>
    {sub && <div style={{fontSize:11, color:"var(--color-text-tertiary)", marginTop:2}}>{sub}</div>}
  </div>
);

const pages = {
  overview: () => (
    <div>
      <p style={{fontSize:14, lineHeight:1.8, color:"var(--color-text-secondary)", marginBottom:20}}>
        Kodomon (コードモン) is a macOS desktop widget — a Tamagotchi-style virtual pet that lives and grows from your real coding activity. The more consistently you code with Claude Code, the healthier and more powerful your crab companion becomes. Neglect it and it suffers. Abandon it and it runs away.
      </p>
      <div style={{display:"flex", gap:10, flexWrap:"wrap", marginBottom:20}}>
        <Stat label="Target to max" value="~3mo" sub="consistent coder" color="#7F77DD"/>
        <Stat label="Daily XP cap" value="200" sub="before diminishing returns" color="#1D9E75"/>
        <Stat label="Evolutions" value="4" sub="Tamago→Kobito→Kani→Kamisama" color="#D85A30"/>
        <Stat label="Platform" value="macOS" sub="Swift, open source MIT" color="#BA7517"/>
      </div>
      <Card title="Core design pillars" accent="#7F77DD">
        <ul style={{margin:0, paddingLeft:18}}>
          <li><strong>Consistency beats intensity.</strong> A daily coder beats a weekend warrior every time. XP gates require real calendar days, not just raw points.</li>
          <li><strong>Absence has real cost.</strong> XP decays when you stop coding. Long gaps can trigger de-evolution. The pet has actual needs.</li>
          <li><strong>Unpredictability creates attachment.</strong> Random events, mood swings, and surprise boosts make it feel alive, not algorithmic.</li>
          <li><strong>Rewarding real developer behavior.</strong> Commits, fixing errors, touching diverse file types — not just keeping a file open.</li>
        </ul>
      </Card>
      <Card title="Data sources" accent="#1D9E75">
        <Table
          heads={["Source", "What we track", "Status"]}
          rows={[
            ["Claude Code logs", "Session time, active minutes", "v1.0"],
            ["Git hooks", "Commits, diffs, lines changed", "v1.0"],
            ["File system events", "Saves, new files, file types", "v1.0"],
            ["Cursor / Codex", "Session activity", "v2.0"],
            ["OpenCode", "Session activity", "Future"],
          ]}
          accents={["#1D9E75","#1D9E75","#1D9E75","#BA7517","#888780"]}
        />
        <p style={{margin:"8px 0 0", fontSize:12}}>All tracking is local — no data leaves the machine. Open source, auditable.</p>
      </Card>
    </div>
  ),

  xp: () => (
    <div>
      <Card title="XP sources" accent="#1D9E75">
        <Table
          heads={["Action", "XP", "Notes"]}
          rows={[
            ["Claude Code active minute", "+2 XP", "capped at 120 min/day = 240 XP raw"],
            ["Small commit (1–25 lines)", "+25 XP", "any commit counts"],
            ["Medium commit (26–100 lines)", "+60 XP", "solid chunk of work"],
            ["Large commit (101–300 lines)", "+150 XP", "real feature territory"],
            ["Huge commit (301–500 lines)", "+350 XP", "big ship day"],
            ["Legendary commit (500+ lines)", "+500–800 XP", "scales with size, capped at 800"],
            ["50 lines of code written", "+1 XP", "nearly negligible — Claude writes fast"],
            ["Bug fixed (error→no error)", "+15 XP", "detected via linter/compiler output"],
            ["New file created", "+10 XP", "once per file per day"],
            ["Variety bonus", "+20 XP", "3+ different file types in a session"],
            ["First code of the day", "+10 XP", "login bonus, encourages daily habit"],
          ]}
        />
        <p style={{margin:"10px 0 0", fontSize:12, color:"var(--color-text-tertiary)"}}>
          Note: lines-of-code XP is intentionally tiny. Claude Code users can accept thousands of AI-written lines per session — rewarding raw line count would let anyone max out in an hour. Commits represent intentional decisions and are the primary XP driver.
        </p>
      </Card>
      <Card title="Daily cap & diminishing returns" accent="#BA7517">
        <p style={{margin:"0 0 10px"}}>To prevent weekend grinding, XP rate drops after sustained sessions:</p>
        <Table
          heads={["Session time", "XP rate", "Reasoning"]}
          rows={[
            ["0–90 min", "100%", "sweet spot, full rate"],
            ["90–180 min", "60%", "still productive, slight cap"],
            ["180+ min", "25%", "heavy session, heavily diminished"],
          ]}
        />
        <p style={{margin:"10px 0 0", fontSize:12}}>Hard daily XP cap: <strong>900 XP/day</strong>. A legendary commit (800 XP) + session time + bonuses can approach this. On a normal productive day expect 150–350 XP. The cap only matters on truly massive ship days — which should feel special, not routine.</p>
      </Card>
      <Card title="Streak multiplier" accent="#7F77DD">
        <Table
          heads={["Streak", "Multiplier", "Feel"]}
          rows={[
            ["1–2 days", "1.0x", "baseline"],
            ["3–6 days", "1.2x", "warming up"],
            ["7–13 days", "1.5x", "on a roll"],
            ["14–29 days", "1.8x", "unstoppable"],
            ["30+ days", "2.0x", "legendary grind"],
          ]}
          accents={["#888780","#1D9E75","#1D9E75","#7F77DD","#D85A30"]}
        />
        <p style={{margin:"10px 0 0", fontSize:12}}>Streak is broken by any day with zero qualifying activity. Miss one day = back to 1.0x. This makes the multiplier feel precious.</p>
      </Card>
    </div>
  ),

  evolution: () => (
    <div>
      <p style={{fontSize:13, color:"var(--color-text-secondary)", lineHeight:1.7, marginBottom:16}}>
        Evolution requires <strong>both</strong> accumulated XP and minimum calendar days. You cannot rush evolution by grinding. The day gates are hard floors — no exceptions.
      </p>

      {[
        {
          name: "Tamago", kanji: "卵", stage: "Stage 0", color: "#888780",
          xp: "0 XP", days: "Day 0", streak: "—", desc: "The egg. Just installed. Sits still, pulses faintly. Waiting.",
          anim: "slow pulse, faint glow", unlock: "Nothing yet — just potential."
        },
        {
          name: "Kobito", kanji: "小人", stage: "Stage 1", color: "#1D9E75",
          xp: "3000 XP", days: "5 active days", streak: "3-day streak at time of evolve",
          desc: "A tiny baby crab hatches. Wiggles its claws. Reacts to commits with happy animation.",
          anim: "idle wiggle, claw snap on commit", unlock: "First hat unlocks. Can now show coding streak badge."
        },
        {
          name: "Kani", kanji: "蟹", stage: "Stage 2", color: "#D85A30",
          xp: "20000 XP", days: "21 active days", streak: "7-day streak at time of evolve",
          desc: "Full crab. Confident, expressive. Dances on big commits. Shows stress when neglected.",
          anim: "dance, stress twitching, sleep animation", unlock: "Background themes, accessories. Stats panel."
        },
        {
          name: "Kamisama", kanji: "神様", stage: "Stage 3", color: "#7F77DD",
          xp: "100000 XP", days: "60 active days", streak: "14-day streak at time of evolve",
          desc: "God crab. Floats slightly. Glows. Radiates calm power. Rare idle animations. Legendary.",
          anim: "float loop, particle aura, rare dances", unlock: "All cosmetics. Kamisama badge. Profile sharing card."
        },
      ].map(s => (
        <Card key={s.name} title={`${s.stage} — ${s.name} ${s.kanji}`} accent={s.color}>
          <div style={{display:"flex", gap:16, flexWrap:"wrap"}}>
            <div style={{flex:2, minWidth:200}}>
              <p style={{margin:"0 0 8px"}}>{s.desc}</p>
              <div style={{marginBottom:6}}>
                <Tag c={s.color}>{s.xp}</Tag>
                <Tag c={s.color}>{s.days}</Tag>
                {s.streak !== "—" && <Tag c="#7F77DD">{s.streak} required</Tag>}
              </div>
            </div>
            <div style={{flex:1, minWidth:160}}>
              <div style={{fontSize:11, fontWeight:500, color:"var(--color-text-tertiary)", marginBottom:4}}>ANIMATIONS</div>
              <div style={{fontSize:12, color:"var(--color-text-secondary)"}}>{s.anim}</div>
              <div style={{fontSize:11, fontWeight:500, color:"var(--color-text-tertiary)", marginTop:8, marginBottom:4}}>UNLOCKS</div>
              <div style={{fontSize:12, color:"var(--color-text-secondary)"}}>{s.unlock}</div>
            </div>
          </div>
        </Card>
      ))}
    </div>
  ),

  decay: () => (
    <div>
      <Card title="Neglect timeline" accent="#E24B4A">
        <Table
          heads={["Time away", "State", "Visual", "XP effect"]}
          rows={[
            ["2h no activity", "Hungry", "droopy eyes, slow blink", "none yet"],
            ["8h no activity", "Tired", "yawning, grey tint", "none yet"],
            ["1 missed day", "Sad", "slouched, occasional sigh", "-3% total XP"],
            ["3 missed days", "Sick", "grey, shivering, X eyes", "-8% total XP per day"],
            ["7 missed days", "Critical", "barely moving, flat color", "-15% total XP per day"],
            ["14 missed days", "Ran away", "empty widget, note left behind", "stage loss possible"],
          ]}
          accents={["#BA7517","#BA7517","#D85A30","#D85A30","#E24B4A","#E24B4A"]}
        />
      </Card>
      <Card title="De-evolution rules" accent="#E24B4A">
        <p style={{margin:"0 0 10px"}}>De-evolution adds genuine stakes. Rules:</p>
        <ul style={{margin:0, paddingLeft:18, fontSize:13}}>
          <li>If XP drops below the <strong>entry threshold</strong> of your current stage, de-evolution triggers.</li>
          <li>De-evolution plays a sad animation — this should feel genuinely bad.</li>
          <li>You keep your calendar day count. You don't lose everything. But you must re-earn the XP.</li>
          <li>Kamisama → Kani requires dropping below 70,000 XP (not 100,000 — a grace buffer).</li>
          <li>There is a <strong>3-day grace period</strong> after reaching a new stage before de-evolution can occur.</li>
        </ul>
      </Card>
      <Card title="Revival mechanic" accent="#1D9E75">
        <p style={{margin:0}}>If your pet ran away (14 days absent), it's not gone forever. When you return:</p>
        <ul style={{margin:"8px 0 0", paddingLeft:18, fontSize:13}}>
          <li>A "revival session" is triggered — code for 30 continuous minutes and Kodomon returns.</li>
          <li>Returns at previous stage minus one (Kamisama comes back as Kani).</li>
          <li>XP is set to midpoint of that stage's range.</li>
          <li>A "survivor" badge is awarded — visible forever.</li>
        </ul>
      </Card>
    </div>
  ),

  mood: () => (
    <div>
      <p style={{fontSize:13, color:"var(--color-text-secondary)", lineHeight:1.7, marginBottom:16}}>
        Mood is a secondary stat (0–100) that acts as an XP multiplier and drives visual behavior. It changes based on coding quality signals, not just quantity.
      </p>
      <Card title="Mood score" accent="#7F77DD">
        <Table
          heads={["Mood range", "Label", "XP multiplier", "Visual"]}
          rows={[
            ["80–100", "Ecstatic", "1.3x", "bouncing, sparkles"],
            ["60–79", "Happy", "1.15x", "relaxed wiggle"],
            ["40–59", "Neutral", "1.0x", "idle"],
            ["20–39", "Stressed", "0.85x", "twitchy, side-eyes"],
            ["0–19", "Miserable", "0.6x", "grey, slumped"],
          ]}
          accents={["#7F77DD","#1D9E75","#888780","#BA7517","#E24B4A"]}
        />
      </Card>
      <Card title="What affects mood" accent="#1D9E75">
        <Table
          heads={["Event", "Mood change"]}
          rows={[
            ["Commit pushed", "+8"],
            ["Error fixed (linter clear)", "+12"],
            ["Long uninterrupted session (45+ min)", "+10"],
            ["Variety bonus triggered", "+6"],
            ["First code of day", "+15"],
            ["Hour of no activity (during work hours)", "-10"],
            ["Day missed entirely", "-20"],
            ["Streak broken", "-15"],
            ["Long error state (build failing 30+ min)", "-8"],
          ]}
        />
        <p style={{margin:"10px 0 0", fontSize:12}}>Mood decays toward 50 (neutral) overnight — it resets partially each day so a bad day doesn't permanently hurt you.</p>
      </Card>
    </div>
  ),

  events: () => (
    <div>
      <p style={{fontSize:13, color:"var(--color-text-secondary)", lineHeight:1.7, marginBottom:16}}>
        Random events fire once per day with ~30% probability. They add surprise and emotional texture. Some are good, some are challenging. The player has no control over when they trigger.
      </p>
      <Card title="Positive events" accent="#1D9E75">
        <Table
          heads={["Event", "Effect", "Trigger condition"]}
          rows={[
            ["Coding storm", "2x XP for next 60 min", "random, any day"],
            ["Good vibes", "+30 mood instantly", "after 3+ day streak"],
            ["Lucky commit", "next commit worth 3x", "random"],
            ["Shell gift", "bonus cosmetic item drops", "stage 2+, random"],
            ["Flow state", "no diminishing returns for 45 min", "after 45 min unbroken session"],
          ]}
        />
      </Card>
      <Card title="Challenge events" accent="#BA7517">
        <Table
          heads={["Event", "Effect", "How to resolve"]}
          rows={[
            ["Bug invasion", "-50 XP unless you fix 3 files in 2h", "code your way out"],
            ["Homesick", "mood locked at 30 for the day", "just ride it out"],
            ["Code drought", "XP halved until next commit", "commit something, anything"],
            ["Restless night", "starts day at 40 mood", "first commit resets it"],
          ]}
        />
      </Card>
      <Card title="Rare events (1% chance)" accent="#7F77DD">
        <Table
          heads={["Event", "Effect"]}
          rows={[
            ["Kani festival", "triple XP all day, special animation"],
            ["Ancient bug", "lose 200 XP but gain a permanent +5 base XP/commit forever"],
            ["Developer god visits", "Kamisama appears briefly even if not evolved — foreshadowing"],
          ]}
        />
      </Card>
    </div>
  ),

  unlockables: () => (
    <div>
      <Card title="Accessories" accent="#7F77DD">
        <Table
          heads={["Item", "Unlock condition", "Slot"]}
          rows={[
            ["Tiny headband", "First commit", "head"],
            ["Pixel sunglasses", "7-day streak", "face"],
            ["Dev hoodie", "100 commits", "body"],
            ["Sakura crown", "Spring (March–May) + Kani", "head"],
            ["Golden claws", "Kamisama evolved", "claws"],
            ["Anthropic logo pin", "30-day streak", "body"],
            ["Katana", "10,000 XP milestone", "held"],
            ["Ramen bowl", "Revived from runaway", "held"],
          ]}
        />
      </Card>
      <Card title="Background themes" accent="#1D9E75">
        <Table
          heads={["Theme", "Unlock"]}
          rows={[
            ["Tokyo night", "default, always unlocked"],
            ["Sakura season", "Kani + spring month"],
            ["Deep sea", "Kamisama evolved"],
            ["Terminal green", "50 consecutive days"],
            ["Cyberpunk city", "100-day streak"],
            ["Tatami room", "30 days at Kani+"],
          ]}
        />
      </Card>
      <Card title="Achievement badges" accent="#D85A30">
        <Table
          heads={["Badge", "Condition"]}
          rows={[
            ["First hatch", "Egg → Kobito"],
            ["Marathoner", "Single 3h+ session"],
            ["Ghosted & returned", "Revival mechanic triggered"],
            ["Survivor", "Came back from ran-away state"],
            ["Legendary", "Reach Kamisama"],
            ["Immortal", "Reach Kamisama twice (after de-evolve)"],
            ["Night owl", "Commits after midnight, 5 nights"],
            ["10k club", "10,000 lines written total"],
          ]}
        />
      </Card>
    </div>
  ),

  social: () => (
    <div>
      <Card title="Shareable card — Kodomon Wrapped" accent="#7F77DD">
        <p style={{margin:"0 0 10px"}}>A locally-generated PNG card the user can share anywhere. No server, no account — generated on device from local stats. Triggered manually from the widget menu, or auto-prompted on evolution and major milestones.</p>
        <Table
          heads={["Card element", "Detail"]}
          rows={[
            ["Pet sprite", "Current evolution stage, full pixel art render"],
            ["Stage name + kanji", "e.g. Kamisama 神様 in Japanese typography"],
            ["Days alive", "e.g. 'Day 84' — the most honest flex"],
            ["Total XP", "lifetime accumulated"],
            ["Longest streak", "e.g. '23-day streak' in a badge"],
            ["Biggest commit", "e.g. 'Legendary: 847 lines'"],
            ["Accessories worn", "renders with current cosmetics equipped"],
            ["Date generated", "subtle — 'March 2026'"],
            ["Kodomon branding", "small logo + kodomon.app URL for organic growth"],
          ]}
        />
        <p style={{margin:"10px 0 0", fontSize:12}}>Visual style: dark background, Japanese pixel aesthetic, cherry blossom or circuit board motif. Two variants — portrait (mobile share) and landscape (Twitter/X card). Both generated as PNG via SwiftUI canvas rendering. No watermark, no forced sharing — just beautiful enough that people want to.</p>
      </Card>

      <Card title="Leaderboard — opt-in, dignity preserved" accent="#1D9E75">
        <p style={{margin:"0 0 10px"}}>Global leaderboard ranked by <strong>days alive</strong>, not XP or stage. This rewards consistency over grinding and can't be gamed by big sessions. Completely opt-in — disabled by default, one toggle to join.</p>
        <Table
          heads={["Design decision", "Reasoning"]}
          rows={[
            ["Ranked by days alive", "Can't be gamed, rewards genuine consistency"],
            ["Anonymous by default", "Username optional — many will prefer just a location flag"],
            ["Stage shown as icon", "Visual indicator of progress without raw numbers"],
            ["No real-time updates", "Refreshes daily — reduces anxiety, not a stock ticker"],
            ["Filter by country / region", "Local competition feels more achievable"],
            ["Opt-out anytime", "Leaving removes your entry immediately"],
            ["No dead accounts", "Entries hidden if pet ran away — leaderboard stays alive"],
          ]}
        />
        <p style={{margin:"10px 0 0", fontSize:12}}>Data sync: minimal — just days alive, stage, username, region. Synced to a lightweight leaderboard server (or GitHub-based static JSON for v1 to keep it free to run). Privacy-first: no email, no auth required to join.</p>
      </Card>

      <Card title="Desktop notifications — sparingly, with personality" accent="#D85A30">
        <p style={{margin:"0 0 10px"}}>Notifications should feel like the pet reaching out, not an app demanding attention. Maximum 2 per day. User can set quiet hours. All dismissible. Tone is always the pet's voice, never the app's.</p>
        <Table
          heads={["Trigger", "Notification copy", "Timing"]}
          rows={[
            ["2h no activity (hungry)", "「お腹すいた…」 Kodomon is getting hungry. Maybe a quick commit?", "once, mid-afternoon only"],
            ["8h no activity (tired)", "「ねむい…」 Kodomon misses you. It's been a long day.", "once, evening only"],
            ["Streak about to break (11:30pm)", "「がんばって！」 Your streak ends at midnight. One commit saves it.", "only if streak ≥ 3 days"],
            ["Evolution ready", "「もうすぐ…！」 Kodomon feels something changing. Keep going.", "fires once when gate is met"],
            ["Random event triggered", "「コーディングストーム！」 A coding storm is here — 2x XP for 60 min!", "as it happens"],
            ["Pet ran away", "「さようなら…」 Kodomon has left. But it left something behind.", "once, morning after"],
          ]}
        />
        <p style={{margin:"10px 0 0", fontSize:12}}>Technical: macOS UserNotifications framework. Notifications include a small sprite image of the pet's current state. No badge count on app icon — too aggressive. Sound is off by default, optional chirp sound toggle in settings.</p>
      </Card>

      <Card title="Viral moments — designed, not accidental" accent="#BA7517">
        <p style={{margin:"0 0 4px"}}>Moments in the product designed to make people want to share or tell someone:</p>
        <ul style={{margin:"8px 0 0", paddingLeft:18, fontSize:13}}>
          <li><strong>First hatch</strong> — full-screen animation, share prompt appears naturally</li>
          <li><strong>Kamisama evolution</strong> — the most shareable moment in the game, card auto-generated</li>
          <li><strong>Legendary commit</strong> — widget flashes, pet does rare animation, "screenshot this" energy</li>
          <li><strong>30-day streak</strong> — badge unlocks + share prompt</li>
          <li><strong>Revival</strong> — "I brought my Kodomon back from the dead" is a good story</li>
          <li><strong>Leaderboard rank milestone</strong> — "I just hit top 100" notification (opt-in only)</li>
        </ul>
      </Card>
    </div>
  ),

  timeline: () => (
    <div>
      <p style={{fontSize:13, color:"var(--color-text-secondary)", lineHeight:1.7, marginBottom:16}}>
        Modeled on a developer coding ~2 hours/day with Claude Code, making commits, maintaining reasonable streaks.
      </p>
      <Card title="Consistent coder (target path)" accent="#7F77DD">
        <Table
          heads={["Period", "Milestone", "XP range", "Notes"]}
          rows={[
            ["Day 1–3", "Egg period", "0–400 XP", "gets acquainted, first animations"],
            ["Day 5–7", "Egg hatches → Kobito", "3000 XP", "requires 5 active days + 3-day streak"],
            ["Week 3–5", "Kobito thriving", "5000–10000 XP", "streak multiplier kicking in"],
            ["Week 6–8", "Kani evolution", "20000 XP", "requires 21 active days + 7-day streak"],
            ["Month 2–4", "Kani growing", "30000–60000 XP", "accessories unlocking, events firing"],
            ["Month 4–6", "Approaching Kamisama", "80000+ XP", "streak multiplier at 1.8–2x"],
            ["~Day 150–200", "Kamisama", "100000 XP", "requires 60 active days + 14-day streak"],
          ]}
          accents={["#888780","#1D9E75","#1D9E75","#D85A30","#D85A30","#7F77DD","#7F77DD"]}
        />
      </Card>
      <Card title="Casual coder (1h/day, occasional gaps)" accent="#BA7517">
        <Table
          heads={["Milestone", "Estimated time"]}
          rows={[
            ["Kobito hatch", "~3–4 weeks"],
            ["Kani", "~5–6 months"],
            ["Kamisama", "10–12 months"],
          ]}
        />
      </Card>
      <Card title="Grinder (4h+ days, no gaps)" accent="#D85A30">
        <Table
          heads={["Milestone", "Estimated time", "Note"]}
          rows={[
            ["Kobito", "5 days (minimum)", "day gate is hard floor"],
            ["Kani", "21 days (minimum)", "can't be rushed past day gate"],
            ["Kamisama", "60 days (minimum)", "hard floor regardless of XP"],
          ]}
        />
        <p style={{margin:"10px 0 0", fontSize:12}}>The day gates are the equalizer. No matter how much someone grinds, Kamisama takes at minimum 60 active days. That's the design.</p>
      </Card>
    </div>
  ),
};

export default function App() {
  const [active, setActive] = useState("overview");

  return (
    <div style={{fontFamily:"var(--font-sans)", maxWidth:800, margin:"0 auto", padding:"16px 0"}}>
      <div style={{marginBottom:20}}>
        <div style={{display:"flex", alignItems:"baseline", gap:12, marginBottom:4}}>
          <span style={{fontSize:22, fontWeight:500, color:"var(--color-text-primary)"}}>Kodomon</span>
          <span style={{fontSize:14, color:"var(--color-text-tertiary)"}}>コードモン</span>
          <span style={{fontSize:11, padding:"2px 8px", borderRadius:20,
            background:"var(--color-background-secondary)",
            border:"1px solid var(--color-border-tertiary)",
            color:"var(--color-text-tertiary)"}}>GDD v0.1</span>
        </div>
        <div style={{fontSize:13, color:"var(--color-text-secondary)"}}>Game Design Document — macOS virtual pet powered by your Claude Code activity</div>
      </div>

      <div style={{display:"flex", gap:6, flexWrap:"wrap", marginBottom:20}}>
        {sections.map(s => (
          <button key={s} onClick={() => setActive(s)} style={{
            padding:"5px 12px", borderRadius:20, fontSize:12, fontWeight:500,
            cursor:"pointer", border:"1px solid",
            borderColor: active===s ? "#7F77DD" : "var(--color-border-tertiary)",
            background: active===s ? "#7F77DD22" : "var(--color-background-secondary)",
            color: active===s ? "#7F77DD" : "var(--color-text-secondary)",
            transition:"all .15s"
          }}>{nav[s]}</button>
        ))}
      </div>

      <div>{pages[active]?.()}</div>
    </div>
  );
}
