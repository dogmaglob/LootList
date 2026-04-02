# LootList — Development Journal

## 2026-04-02 — Project Setup & Planning

### Current state
Inherited a minimal SwiftUI + SwiftData skeleton (originally named `claude_test`). Models: `LootItem`, `Carrier`. Views: `ContentView`, `AddLootView`, `EditLootView`, `CarrierPickerView`, `CarriersView`. No campaigns, no filtering, no sharing, no events.

### What was done
- Created `DESIGN.md` with full v1 design decisions and a 10-phase implementation plan.
- Added `CLAUDE.md` with coding standards (iOS 26+, Swift 6.2+, `@Observable`, async/await, `FormatStyle`, SwiftLint, Xcode MCP, etc.).
- Updated implementation plan to comply with `CLAUDE.md`: CloudKit-safe model constraints from Phase 1, `@Observable @MainActor` throughout, no `@EnvironmentObject`, `localizedStandardContains()` for search, `FormatStyle` for all formatting, `ShareLink` over `UIActivityViewController`, feature-based folder structure.
- App name decided: **LootList**.

### Key decisions logged
- CloudKit constraints (no `@Attribute(.unique)`, optional relationships, defaulted properties) applied from Phase 1 to avoid a second migration later.
- `AppState` will be an `@Observable @MainActor` class holding `activeCampaign`, injected via `@Environment` — not `@EnvironmentObject`.
- `SharingProvider` protocol abstracts iCloud so the backend can be swapped without touching the rest of the app.
- `LootEvent` stores item name as a String snapshot so the log survives item deletion.
