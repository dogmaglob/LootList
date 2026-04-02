# D&D Loot Tracker — Design Document

## Current State (from codebase)

- iOS app built with SwiftUI + SwiftData
- Loot items have: name, category, quantity, weight, value, carrier, notes, dateAdded
- Categories: Weapon, Armor, Potion, Gold, Gem, Scroll, Misc (each with an emoji icon)
- Carriers: named party members; each owns a list of loot items
- Main list sorted by date added (newest first), swipe-to-delete
- Add/Edit loot via sheets; carrier picked via NavigationLink sub-screen

---

## Design Decisions

### Vision & Scope

- **Primary user** — Both players and dungeon masters.
- **Game systems** — System agnostic. No rules-specific assumptions baked in.
- **Sharing** — Party-wide sharing via iCloud shared database. All party members have equal permissions. The sharing implementation must be abstracted behind a protocol so the backend (iCloud today, join code/link in future) can be swapped without touching the rest of the app.
- **Campaigns** — Multiple campaigns, each with their own separate loot pool and carriers.

### Core Gameplay Loop

- **Currency** — Single "value" number.
- **Carry weight** — Track total weight per carrier but do not enforce limits.
- **Consumables** — One-tap "use" decrements quantity by 1 and logs a "used" event. Item is removed when quantity reaches 0.
- **Item history / log** — Log events for: found, sold, and used. Each event records the item and timestamp.

### Items & Categories

- **Categories** — Built-in seven (Weapon, Armor, Potion, Gold, Gem, Scroll, Misc) plus user-defined custom categories with a name and emoji icon.
- **Magic item rarity** — Not supported (system agnostic).
- **Spell scrolls** — Free-text notes only.

### Carriers / Party

- **Carrier data** — Name only.
- **Uncarried items** — Items with no carrier assigned are implicitly the party stash. No special container needed.
- **Carrier filtering** — Filter by carrier from the main list in one or two taps (quick-filter chips/buttons). No dedicated carrier detail screen.

### UX & Polish

- **Visual theme** — Clean, modern iOS strictly adhering to Apple HIG.
- **iPad** — Supported with split-column layout.
- **Quick entry** — Voice input (speech-to-text) and a quick-add bar for fast entry at the table. Full form available for detailed entry.
- **Search & filter** — Filters in priority order: carrier, date found range, category, value range.
- **Sorting** — Date added only (newest first).

### Sharing & Export

- **iCloud sync** — Covered by party-wide iCloud sharing; all user's own devices stay in sync automatically.
- **Export** — CSV.

---

---

## Implementation Plan

### Overview

The existing codebase is a minimal SwiftUI + SwiftData skeleton. All work below brings it to the full v1 spec. Phases are ordered by dependency; later phases build on earlier ones.

---

### Phase 1 — App Rename & Data Model Foundation

**Goal:** Establish the correct data shape before any UI work. All later phases depend on this.

**Tasks:**
- Rename the Xcode target/bundle from `claude_test` to `LootList`
- Add `Campaign` SwiftData model: `id`, `name`, `createdAt`
- Add `CustomCategory` SwiftData model: `id`, `name`, `emoji`, `campaign` (relationship)
- Add `LootEvent` SwiftData model: `id`, `type` (enum: found/sold/used), `itemName` (String snapshot), `timestamp`, `campaign` (relationship)
- Update `LootItem`: add `campaign` relationship (required); add `customCategory: CustomCategory?` alongside the existing `LootCategory` enum field; add a computed `displayCategory` that returns whichever is set
- Update `Carrier`: add `campaign` relationship (required)
- Implement versioned SwiftData schema migration from v1 (current) → v2 (with Campaign); existing items/carriers land in an auto-created "Default Campaign"
- Update `claude_testApp` entry point: register all new models in the `ModelContainer`; inject an `activeCampaign` environment object

**Key decisions:**
- `LootEvent` stores a String snapshot of the item name so the log survives item deletion
- `CustomCategory` is campaign-scoped so different campaigns can have different category sets
- Migration creates one "Default Campaign" and re-parents all orphaned items/carriers into it

---

### Phase 2 — Campaign Management

**Goal:** Users can create, select, and delete campaigns. All loot/carrier queries are scoped to the active campaign.

**Tasks:**
- `CampaignListView`: shows all campaigns with item counts; tap to activate; swipe to delete (with confirmation); inline "New Campaign" text field
- App root becomes a `CampaignListView` when no campaign is selected; once selected, pushes to the loot list
- Thread active campaign through the environment (`@EnvironmentObject` or SwiftData predicate injection)
- Update all `@Query` calls in `ContentView`, `CarriersView`, `AddLootView` etc. to filter by active campaign

---

### Phase 3 — Consumable Use, Sell & Item Event Log

**Goal:** Items can be "used" or "sold" from the list; all events are logged.

**Tasks:**
- Insert a `LootEvent(.found, ...)` when a new `LootItem` is created
- Add swipe-trailing actions on each loot row: **Use** (for consumables/stackables) and **Sell**
  - **Use**: decrement `quantity` by 1; insert `LootEvent(.used)`; if `quantity` reaches 0, delete the item
  - **Sell**: insert `LootEvent(.sold)`; delete the item
- `EventLogView`: full list of events for the active campaign, sorted newest-first; accessible via toolbar icon on the main loot list
- Each event row shows: icon, item name, event type, and formatted timestamp

---

### Phase 4 — Search & Filtering

**Goal:** Players can quickly narrow the loot list to what they care about.

**Tasks:**
- Search bar at the top of the loot list (filters by item name)
- Quick-filter carrier chips: a horizontally scrolling row of chips below the search bar — one chip per carrier plus **All** and **Stash** (no carrier); tapping a chip filters the list
- Filter sheet (funnel toolbar icon):
  - Category multi-select (built-in + custom)
  - Date found range (DatePicker start/end)
  - Value range (min/max text fields)
- All active filters combine with AND logic
- Filter state lives in the view model / view; not persisted between sessions

---

### Phase 5 — Custom Categories

**Goal:** Users can define their own categories with a name and emoji, per campaign.

**Tasks:**
- `CustomCategoryManagerView`: list of custom categories for the active campaign; inline add (name + emoji picker); swipe to delete
- Accessible from the Carriers screen or a dedicated Settings screen
- Update the category picker in `AddLootView` and `EditLootView` to show built-in categories first, then a "Custom" section with user-defined ones
- Items assigned to a deleted custom category fall back to `.misc`

---

### Phase 6 — Quick Add & Voice Input

**Goal:** Fast loot entry during play without opening a full form sheet.

**Tasks:**
- **Quick-add bar**: a persistent bar at the bottom of the loot list (above the tab bar / safe area) with a text field and a "+" button; entering a name and tapping "+" creates an item with defaults (category: misc, quantity: 1, no carrier); item is created immediately and the bar resets
- **Voice button**: microphone icon in the quick-add bar; taps activate `SFSpeechRecognizer` live transcription; transcribed text fills the name field; tapping again or detecting silence commits the text
- Privacy usage description added to `Info.plist` for speech recognition
- Full-form sheet remains available via the existing "+" toolbar button for detailed entry

---

### Phase 7 — iPad Layout

**Goal:** The app makes use of iPad screen space with a split-column layout.

**Tasks:**
- Replace `NavigationStack` root with `NavigationSplitView`:
  - **Sidebar**: campaign list + navigation links (Carriers, Event Log, Settings)
  - **Content**: loot list for the active campaign (with search/filter/quick-add)
  - **Detail**: item detail / edit form, or a placeholder "Select an item"
- Carrier quick-filter chips collapse into a sidebar section on iPad
- All existing iPhone layouts remain unchanged (compact size class uses the stacked navigation)

---

### Phase 8 — iCloud Sharing

**Goal:** A party can share one campaign database so all members see the same loot in real time.

**Tasks:**
- Define `SharingProvider` protocol: `share(campaign:)`, `acceptShare(metadata:)`, `isShared(campaign:) -> Bool`
- Implement `CloudKitSharingProvider` using `SwiftData` + `NSPersistentCloudKitContainer` shared zones
- Add a **Share Campaign** button to the campaign detail / settings; invokes the system `UICloudSharingController`
- All party members who accept the share get full read/write (no role distinction in v1)
- `LocalSharingProvider` (no-op) is the default for users who don't want iCloud
- The active provider is injected via the environment so the rest of the app never imports CloudKit directly

---

### Phase 9 — CSV Export

**Goal:** Users can export the current campaign's loot as a CSV file.

**Tasks:**
- Export action in the campaign settings / toolbar: generates a CSV with columns: Name, Category, Quantity, Weight, Value, Carrier, Notes, Date Added
- Uses standard `ShareLink` / `UIActivityViewController` so users can AirDrop, save to Files, email, etc.
- Filename: `LootList-<CampaignName>-<YYYY-MM-DD>.csv`

---

### Out of Scope for v1

Everything listed under **Future Features** below.

---

## Future Features (Planned, Not in v1)

- Loot splitting tools
- Multi-denomination currency (CP/SP/GP/PP) with conversion
- Encumbrance enforcement with configurable limits
- Unidentified items (DM reveals)
- Attunement tracking
- Spell scroll database links
- DM/player roles and permissions
- Carrier character stats (class, level, STR, portrait)
- Magic item rarity tiers
- Home screen widgets
- PDF and Markdown export
- Join code / link-based party sharing
