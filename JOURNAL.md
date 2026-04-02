# LootList — Development Journal

## 2026-04-02 — Project Setup & Planning

### Current state
Inherited a minimal SwiftUI + SwiftData skeleton (originally named `claude_test`). Models: `LootItem`, `Carrier`. Views: `ContentView`, `AddLootView`, `EditLootView`, `CarrierPickerView`, `CarriersView`. No campaigns, no filtering, no sharing, no events.

### What was done
- Created `DESIGN.md` with full v1 design decisions and a 10-phase implementation plan.
- Added `CLAUDE.md` with coding standards (iOS 26+, Swift 6.2+, `@Observable`, async/await, `FormatStyle`, SwiftLint, Xcode MCP, etc.).
- Updated implementation plan to comply with `CLAUDE.md`: CloudKit-safe model constraints from Phase 1, `@Observable @MainActor` throughout, no `@EnvironmentObject`, `localizedStandardContains()` for search, `FormatStyle` for all formatting, `ShareLink` over `UIActivityViewController`, feature-based folder structure.
- App name decided: **LootList**.

## 2026-04-02 — Phase 1: Feature-Based Folder Structure

Established feature-based folder layout. Project uses `PBXFileSystemSynchronizedRootGroup` so Xcode picks up filesystem changes automatically — no `.pbxproj` edits required.

```
LootList/
├── LootListApp.swift
├── Loot/          ← LootItem, ContentView, AddLootView, EditLootView
├── Carriers/      ← Carrier, CarriersView, CarrierPickerView
├── Campaigns/     ← (Phase 2)
├── EventLog/      ← (Phase 3)
├── Settings/      ← (Phase 10)
└── Shared/        ← (future utilities)
```

---

## 2026-04-02 — Design change: LootCategory enum replaced with SwiftData model

`LootCategory` enum eliminated. Replaced with a `LootCategory` SwiftData model (`name`, `emoji`, `isBuiltIn`, `sortOrder`). The seven built-ins are seeded on first launch rather than hardcoded as enum cases. `CustomCategory` deleted as it is now redundant — there is one unified category concept.

`LootItem.category` updated from `LootCategory` (enum) to `LootCategory?` (model reference). All `LootItem` properties now have default values (CloudKit-safe).

Views (`AddLootView`, `EditLootView`, `ContentView`) will have compile errors until updated in the relevant phase.

---

## 2026-04-02 — Design change: CustomCategory made app-wide

Removed `campaign` relationship from `CustomCategory` and removed `customCategories` from `Campaign`. Custom categories are now a global, app-wide list shared across all campaigns.

**Why:** Category sets are unlikely to vary significantly between campaigns. Per-campaign scoping adds friction with little benefit.

**Future validation:** A metrics feature is planned to track category usage across campaigns and confirm variance is low. If it turns out variance is high, this decision can be revisited.

---

### Key decisions logged
- CloudKit constraints (no `@Attribute(.unique)`, optional relationships, defaulted properties) applied from Phase 1 to avoid a second migration later.
- `AppState` will be an `@Observable @MainActor` class holding `activeCampaign`, injected via `@Environment` — not `@EnvironmentObject`.
- `SharingProvider` protocol abstracts iCloud so the backend can be swapped without touching the rest of the app.
- `LootEvent` stores item name as a String snapshot so the log survives item deletion.
