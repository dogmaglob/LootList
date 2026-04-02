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

### Development Workflow

- **Code reviews**: Use [OpenAI Codex](https://openai.com/codex) to review code before merging each phase. Use Claude Code at extra high effort for reviews.
- **Linting**: SwiftLint must return no warnings or errors before every commit.

---

### Architecture Standards

These rules apply across every phase:

- **Target**: iOS 26.0+, Swift 6.2+, strict Swift concurrency.
- **Shared state**: `@Observable` classes marked `@MainActor`; passed via `@State` (owner) and `@Environment` / `@Bindable` (consumers). Never use `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, or `@EnvironmentObject`.
- **Concurrency**: async/await throughout. No `DispatchQueue.main.async` or `Task.sleep(nanoseconds:)`.
- **Formatting**: Always use `FormatStyle` APIs — never `DateFormatter`, `NumberFormatter`, or C-style `String(format:)`.
- **Text search**: Always filter user-entered text with `localizedStandardContains()`, never `contains()`.
- **UIKit**: Avoid entirely unless there is no SwiftUI equivalent. Flag any UIKit usage explicitly.
- **Third-party libraries**: Do not add any without explicit approval.
- **Project structure**: Feature-based folder layout; one type per file.
- **Testing**: Unit tests for all core logic; UI tests only where unit tests are not possible.
- **SwiftData + CloudKit constraints** (apply from Phase 1 since CloudKit is a v1 target):
  - No `@Attribute(.unique)` on any model property.
  - All model properties must have default values or be optional.
  - All relationships must be optional.

---

### Overview

The existing codebase is a minimal SwiftUI + SwiftData skeleton. All work below brings it to the full v1 spec. Phases are ordered by dependency; later phases build on earlier ones.

---

### Phase 1 — App Rename & Data Model Foundation

**Goal:** Establish the correct data shape before any UI work. All later phases depend on this.

**Tasks:**
- Rename the Xcode target/bundle from `claude_test` to `LootList`; rename `claude_testApp.swift` → `LootListApp.swift`
- Choose and add an open source license (e.g. MIT or Apache 2.0); add `LICENSE` file to the repo root and `NSHumanReadableCopyright` to `Info.plist`
- Establish feature-based folder structure (e.g. `Campaigns/`, `Loot/`, `Carriers/`, `EventLog/`, `Settings/`, `Shared/`)
- Add `Campaign` SwiftData model: `id: UUID = UUID()`, `name: String = ""`, `createdAt: Date = .now`
- Add `CustomCategory` SwiftData model: `id: UUID = UUID()`, `name: String = ""`, `emoji: String = ""`, `campaign` relationship (optional)
- Add `LootEvent` SwiftData model: `id: UUID = UUID()`, `type` (enum: found/sold/used), `itemName: String = ""`, `timestamp: Date = .now`, `campaign` relationship (optional)
- Update `LootItem`: all properties get default values; `campaign` relationship made optional; `customCategory: CustomCategory?` added alongside existing `LootCategory` field; computed `displayCategory` returns whichever is set; remove any `@Attribute(.unique)` usage
- Update `Carrier`: `campaign` relationship made optional; remove `@Attribute(.unique)` from `name`
- Create `AppState` as an `@Observable @MainActor` class holding `activeCampaign: Campaign?`; inject into the environment via `@State` in `LootListApp`
- Implement versioned SwiftData schema migration from v1 (current) → v2 (with Campaign); existing items/carriers land in an auto-created "Default Campaign"

**Key decisions:**
- All SwiftData model properties have defaults/are optional from the start — CloudKit requires this and it avoids a second migration later
- `@Attribute(.unique)` removed from `Carrier.name` for the same CloudKit reason
- `LootEvent` stores a String snapshot of the item name so the log survives item deletion
- `CustomCategory` is campaign-scoped so different campaigns can have different category sets
- Migration creates one "Default Campaign" and re-parents all orphaned items/carriers into it

---

### Phase 2 — Campaign Management

**Goal:** Users can create, select, and delete campaigns. All loot/carrier queries are scoped to the active campaign.

**Tasks:**
- `CampaignListView`: shows all campaigns with item counts; tap to activate; swipe to delete (with confirmation); inline "New Campaign" text field
- App root becomes a `CampaignListView` when no campaign is selected; once selected, pushes to the loot list
- Thread active campaign via `AppState` (`@Observable @MainActor` class) injected as `@Environment(AppState.self)` — never `@EnvironmentObject`
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
- Each event row shows: icon, item name, event type, and formatted timestamp using `FormatStyle` (e.g. `timestamp.formatted(date: .abbreviated, time: .shortened)`)

---

### Phase 4 — Search & Filtering

**Goal:** Players can quickly narrow the loot list to what they care about.

**Tasks:**
- Search bar at the top of the loot list; item name filtering must use `localizedStandardContains()`, not `contains()`
- Quick-filter carrier chips: a horizontally scrolling row of chips below the search bar — one chip per carrier plus **All** and **Stash** (no carrier); tapping a chip filters the list
- Filter sheet (funnel toolbar icon):
  - Category multi-select (built-in + custom)
  - Date found range (DatePicker start/end)
  - Value range (min/max); display values with `FormatStyle`, never C-style format strings
- All active filters combine with AND logic
- Filter state lives in an `@Observable @MainActor` view model; not persisted between sessions

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
- **Voice button**: a `Button` (not `onTapGesture`) with microphone icon in the quick-add bar; taps activate `SFSpeechRecognizer` live transcription using async/await; transcribed text fills the name field; tapping again or detecting silence commits the text
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
- Define `SharingProvider` protocol with `async throws` methods: `share(campaign:)`, `acceptShare(metadata:)`, `isShared(campaign:) -> Bool`
- Implement `CloudKitSharingProvider` using SwiftData's built-in CloudKit support (not `NSPersistentCloudKitContainer` directly)
- Add a **Share Campaign** button to campaign settings; present the system share UI via SwiftUI — avoid `UICloudSharingController` (UIKit); if no pure SwiftUI equivalent exists at the time of implementation, wrap it in a minimal `UIViewControllerRepresentable` and flag it for future replacement
- All party members who accept the share get full read/write (no role distinction in v1)
- `LocalSharingProvider` (no-op) is the default for users who don't want iCloud
- The active provider is injected via the environment so the rest of the app never imports CloudKit directly

---

### Phase 9 — CSV Export

**Goal:** Users can export the current campaign's loot as a CSV file.

**Tasks:**
- Export action in the campaign settings / toolbar: generates a CSV with columns: Name, Category, Quantity, Weight, Value, Carrier, Notes, Date Added
- Uses SwiftUI `ShareLink` so users can AirDrop, save to Files, email, etc. — do not use `UIActivityViewController`
- Filename: `LootList-<CampaignName>-<YYYY-MM-DD>.csv`

---

### Phase 10 — App Store & End-User Licensing

**Goal:** Ensure the app meets App Store submission requirements and users understand the terms under which they use it.

**Tasks:**
- Draft and host a **Privacy Policy** (required by Apple for apps that collect any user data or use iCloud sharing); link it in the App Store listing and in-app under Settings
- Draft an **End User License Agreement (EULA)**; decide whether to use Apple's standard EULA or a custom one; if custom, host it and link from Settings
- Add a **third-party attributions** screen (Settings → Acknowledgements) listing any open source libraries used and their licenses
- Complete App Store Connect metadata: app description, keywords, screenshots, support URL, privacy nutrition labels (Data Used to Track You, Data Linked to You, etc.)

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
