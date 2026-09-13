# Goalie Shot Tracker

A native iOS app for tracking goalie shots in real time: tap a 3x3 net diagram during a game to log every shot, then break the results down by zone, shot type, danger level, and strength state. Built with SwiftUI, SwiftData, and Swift Charts.

## Overview

The app is split into two pieces on purpose:

- **`Core/`** — a plain, cross-platform Swift package with the domain models, enums, and the stats engine. It has no dependency on UIKit, SwiftUI, or SwiftData, and ships with a full XCTest suite you can run with `swift test` on any machine with a Swift toolchain (Linux included).
- **`GoalieShotTracker/`** — the SwiftUI + SwiftData iOS app itself, opened via `GoalieShotTracker.xcodeproj`. It reuses every file in `Core/` directly (compiled straight into the app target) so the save-percentage math, zone logic, and badge thresholds are exactly what the test suite already verified.

> [!NOTE]
> This project was generated and verified in a Linux environment without Xcode. The Core package's logic is compiled and unit-tested for real (`swift test`, 24/24 passing). The SwiftUI/SwiftData app layer was written against the documented iOS 17 APIs and syntax-checked file by file, but has **not** been built inside Xcode. Open it in Xcode 15+ and do a clean build before relying on it — see [Known Limitations](#known-limitations) below.

## Feature Highlights

- **Live shot logging** — a tap-to-log 3x3 net diagram (glove/center/blocker × high/mid/low) that live-colors each zone by save percentage as the game goes. Two big buttons (SAVE / GOAL) cover the common case in one tap; shot type, strength state, rush/odd-man, and rebound-given are all adjustable without slowing down the flow.
- **Full shot taxonomy** — 10 shot types (wrist, slap, snap, backhand, deflection, one-timer, wraparound, breakaway, penalty shot, shootout), 7 outcomes (frozen save, rebound save, goal, goal-on-rebound, missed net, blocked, post/crossbar), and 7 strength states (even strength, PK, PP, 4-on-4, 3-on-3, penalty shot, shootout).
- **Danger-level scoring** — every shot gets a computed low/medium/high danger rating from its zone, shot type, rush/odd-man context, and strength state — not just its location.
- **Deep analytics** — save % trend line, a read-only zone heatmap, a shot-type bar chart, danger-zone and situational (strength-state) splits, and a home/away comparison, all filterable to last 5, last 10, or all-time games.
- **Badges & milestones** — shutouts, back-to-back shutouts, 30/40-save games, .950+ games, a "high-danger wall" game, a season-long Iron Wall badge (.920+ over 5+ games), a Workhorse badge (10+ games), and 5-game quality-start streaks — all computed from the shot log, not hand-tracked.
- **Multi-goalie roster** — track more than one goalie (a coach's whole tandem, or a parent with two kids in net), each with their own catch hand, jersey number, and independent stats.
- **Game history** — every game gets a full shot-by-shot timeline, a per-period breakdown, and its own CSV export.
- **CSV export** — export a single game or your entire shot log for spreadsheet analysis, via the share sheet.
- **iCloud sync (optional)** — SwiftData + CloudKit keeps stats current across devices; toggle it off in Settings to keep everything local-only.

## Project Structure

```text
shot-tracker-/
├── Core/                              Cross-platform Swift package (no UIKit/SwiftUI/SwiftData)
│   ├── Package.swift
│   ├── Sources/GoalieTrackerCore/
│   │   ├── Enums/                     NetZone, ShotType, ShotOutcome, StrengthState, DangerLevel, Badge, ...
│   │   ├── Models/                    GoalieProfile, Team, Opponent, GameSession, ShotEvent
│   │   └── Stats/                     StatsEngine + its result types
│   └── Tests/GoalieTrackerCoreTests/  24 XCTest cases
├── GoalieShotTracker/                 iOS app target sources
│   ├── GoalieShotTrackerApp.swift
│   ├── Persistence/                   SwiftData @Model entities + ModelContainer setup
│   └── Views/                         Dashboard, Logger, History, Analytics, Roster, Onboarding, Shared
├── GoalieShotTracker.xcodeproj/       Open this in Xcode
└── scripts/generate_xcodeproj.py      Regenerates project.pbxproj if files are added/moved
```

## Getting Started

1. Open `GoalieShotTracker.xcodeproj` in Xcode 15 or later.
2. Select the `GoalieShotTracker` scheme and a simulator running iOS 17+.
3. Build and run.
4. On first launch, walk through onboarding and create a goalie profile — that's the only setup required to start logging shots.

### Running the Core Tests

```sh
cd Core
swift test
```

This runs entirely outside Xcode (Linux or macOS) and exercises the save-percentage math, the danger-level heuristics, and every badge threshold.

### Regenerating the Xcode Project

If you add, remove, or move a Swift file under `GoalieShotTracker/` or `Core/Sources/GoalieTrackerCore/`, update the file lists at the top of `scripts/generate_xcodeproj.py` and re-run it:

```sh
python3 scripts/generate_xcodeproj.py
```

It rebuilds `project.pbxproj` and the shared scheme deterministically from those lists, so the project file never has to be hand-edited in a text editor.

## Architecture Notes

- **Why a separate `Core` package?** So the logic that actually decides save percentage, danger levels, and badges can be tested with plain XCTest, independent of any SwiftUI view or SwiftData store. Every `StatsEngine` function is a pure function over `[ShotEvent]` — same input, same output, no hidden state.
- **SwiftData is a thin shell.** The `@Model` entities in `Persistence/Entities.swift` mirror the `Core` structs field-for-field and expose `asCoreModel` on every entity. Views only ever hand `Core` value types to `StatsEngine` — SwiftData never leaks into the stats logic.
- **The net diagram grid.** `NetZone`'s nine cases are declared in row-major order (high glove → high blocker, then mid, then low), so a plain 3-column `LazyVGrid` over `NetZone.allCases` produces the correct visual layout with no extra positioning code.

## Known Limitations

> [!IMPORTANT]
> These are the concrete gaps worth knowing about before you treat this as finished:

- **Not yet built in Xcode.** The app layer was written and syntax-checked but never compiled against the real iOS SDKs (this was built in a Linux-only environment). Do a clean build in Xcode first — if something doesn't compile, it's most likely a minor SwiftUI API mismatch that's quick to fix.
- **App icon is a placeholder.** A generated 1024×1024 icon is wired up so the app isn't iconless, but you'll likely want your own artwork.
- **CloudKit container isn't provisioned.** The entitlements file references `iCloud.com.kiddreads.goalieshottracker`; you'll need to create that container in your own Apple Developer account (or change the identifier) before iCloud sync will actually work. The app runs fine locally with sync off.
- **No Watch app or widgets yet.** Both would be natural next additions — a Watch complication for in-game logging, and a home-screen widget for season save %.
- **Single-sport zone model.** The 3x3 net grid and danger heuristics are tuned for ice hockey. Extending to other goalie sports (soccer, lacrosse, field hockey) would mean adding a sport-specific zone enum alongside `NetZone`.

## Resources

- [Swift Charts documentation](https://developer.apple.com/documentation/charts)
- [SwiftData documentation](https://developer.apple.com/documentation/swiftdata)

---

Last Updated: September 2026
