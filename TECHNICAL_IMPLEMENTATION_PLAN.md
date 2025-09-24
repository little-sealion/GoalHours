# GoalHours – Technical Implementation Plan

## Overview
GoalHours is a Flutter mobile app to track time against hour goals per project. Users can:
- Create projects with target hour goals
- Track time by starting/stopping a timer OR by entering hours:minutes manually
- See a colorful progress bar per project showing progress toward the goal

Constraints and scope:
- Tech stack: Flutter (iOS + Android)
- Data storage: on-device only (no backend)
- Pricing model:
  - Free: up to 3 projects, with ads
  - Premium: unlimited projects, no ads, one-time $4.99 purchase

## Requirements summary
- Projects
  - Create, edit (name, color, goal), archive/delete
  - Limit to 3 active projects for Free; unlimited with Premium
  - Display progress bar showing accumulated time / goal
- Sessions (time entries)
  - Option 1: Live timer (start/stop) -> persists start time, calculates duration on stop
  - Option 2: Manual entry of duration (HH:MM)
  - List sessions per project, edit/delete entries, notes optional
  - Only one active session app-wide at a time
- Monetization & gating
  - Banner ads in Free
  - Remove ads and project cap with one-time IAP
  - Restore purchases
- Data
  - Stored locally; resilient to app restarts
  - Basic migrations for schema evolution
- UX
  - Projects list (progress bars)
  - Project detail (stats + session list)
  - New/edit project
  - Timer sheet / manual entry dialog

## Architecture (kept simple)
- Keep it minimal and pragmatic; avoid over-abstracting until needed.
- State management: Provider + ChangeNotifier (lightweight)
- Navigation: go_router (single file router)
- Persistence: Isar (local DB). A single repository per entity is enough.
- Time handling: Store UTC timestamps; compute durations from DB values.
- Theming: Material 3; per-project color stored as int; rough_flutter for sketch style.

### Project structure (lean)
```
lib/
  main.dart                # runApp + Providers
  app_router.dart          # all routes in one place
  theme.dart

  data/
    db.dart                # isar init/open helpers
    project.dart           # Isar model + adapters
    session.dart           # Isar model + adapters
    project_repo.dart      # CRUD + aggregate helpers
    session_repo.dart      # timer/manual entry ops

  features/
    projects/
      projects_page.dart   # list + progress bars + FAB
      edit_project_page.dart
      project_detail_page.dart
      projects_ctrl.dart   # providers/controllers
      widgets/
        progress_bar.dart

    timer/
      timer_ctrl.dart          # start/stop, active session
      stopwatch_sheet.dart     # start/pause/stop/save + rounded-minute save
      manual_entry_dialog.dart

    settings/
      settings_page.dart

  monetization/
    purchases.dart         # IAP (premium)
    ads.dart               # banner ads

  utils/
    time_format.dart       # duration/date utilities

assets/
  images/

test/                      # unit & widget tests
integration_test/
  app_test.dart

pubspec.yaml
```

## Data model
- Project
  - id (Isar auto id)
  - name: String (unique per user not required)
  - color: int (ARGB hex)
  - goalMinutes: int
  - sortIndex: int (manual order; defaults 0, indexed)
  - createdAtUtc: DateTime
  - archived: bool (defaults false)
- Session
  - id (Isar auto id)
  - projectId: link to Project
  - startUtc: DateTime
  - endUtc: DateTime? (null if active)
  - isManual: bool
  - manualDurationMinutes: int? (for manual entries; else computed from start/end)
  - note: String?
  - createdAtUtc: DateTime

Constraints and rules:
- At most one session with endUtc == null across the entire DB
- Duration minutes = manualDurationMinutes if isManual else max(0, endUtc - startUtc)
- Accumulated time per project = sum of sessions durations (exclude deleted/archived)

## Key workflows
1) Create project
- Validate Free/Premium cap
- Save project; return to list

2) Start/stop timer
- If another active session exists, prompt to stop it first
- On start: create Session(startUtc=now, isManual=false)
- On stop: set endUtc=now; persist; update aggregates

3) Manual entry
- Input HH:MM; validate range (0–23:59 typical, but allow larger)
- Create Session(isManual=true, manualDurationMinutes=…) with endUtc=now, startUtc=endUtc-duration (for ordering)

4) Progress calculation
- Compute totalMinutes/goalMinutes
- Clamp progress 0..>1; display percent; over-goal visually indicated

5) Free vs Premium logic
- On app start, query purchase state; store in a Provider-backed controller/service
- Enforce project creation limit in UI and repository
- Ads visible if not premium; hidden otherwise

## State management
- Controllers (ChangeNotifier via Provider)
  - ProjectsController: streams Projects with derived totals and progress
  - TimerController: start/stop, single-active-session invariant, elapsed
  - Premium/Ads controller: later

## Persistence layer
- Isar collections: ProjectCollection, SessionCollection
- Indices:
  - Session.projectId
  - Session.endUtc (for active lookup)
- Migrations: use Isar schema versioning; write adapters to backfill new fields


## Time & lifecycle handling
- Store UTC times; convert to local for display
- Active timer UI uses a Ticker/Timer to update every second, but truth source is startUtc saved in DB
- On app pause/terminate, no background service required; elapsed is derived from now - startUtc when resumed
- Handle DST/timezone changes by using UTC

## UI/UX
- Projects list
  - Card per project with:
    - Name, progress bar, elapsed/goal text
    - Start/Stop button (if active session -> shows Stop)
    - More menu: Edit, Archive, Delete
    - Drag to reorder projects (persistent order)
  - FAB: New project (disabled when cap reached in Free)
- Project detail
  - Header: progress ring/bar, goal edit quick action
  - Sessions list: grouped by date (Today/Yesterday/Date), duration, note; swipe to delete/edit
  - Add session: manual entry dialog
- Timer sheet
  - Local-only stopwatch (Option A): Start/Pause/Resume/Stop/Save; after Stop, Save adds a rounded-minute manual entry
  - Expanded height (~80% screen) to reduce accidental taps; Save always enabled; "< 1m, keep going" hint when tiny
  - Next polish: keep screen awake while stopwatch is visible
- Colors
  - Choose from palette; stored per project; progress bar uses project color

## Monetization
- Ads: Google Mobile Ads for Flutter (banner)
  - Show banner on projects list and detail pages in Free
  - Use test ad units in dev; real IDs in prod via flavors or runtime config
- In-App Purchase via RevenueCat (recommended)
  - Use `purchases_flutter` SDK
  - Create one non-consumable entitlement, e.g. `premium` mapped to products on iOS/Android
  - Offer configuration done in RevenueCat dashboard (no server needed)
  - App initializes RevenueCat on launch, fetches `CustomerInfo`, and exposes `isPremium` based on entitlement active state
  - Restore purchases with RevenueCat restore API
  - Keep product identifiers consistent, e.g. iOS: `goalhour_premium_unlimited_noads`, Android: same SKU; entitlement key `premium`

### Platform-specific setup
- iOS
  - IAP: Configure product in App Store Connect; enable In-App Purchases capability
  - RevenueCat: Add API key to app init; optionally add `NSUserTrackingUsageDescription` if using ads
  - Ads: Add GADApplicationIdentifier to Info.plist; ATT if using tracking
- Android
  - IAP: Configure product in Play Console
  - RevenueCat: Add API key to app init; Billing permission is handled by SDK
  - Ads: Add app ID in AndroidManifest.xml

## Dependencies (pubspec.yaml)
- provider
- go_router
- rough_flutter
- isar, isar_flutter_libs, isar_generator, build_runner
- google_mobile_ads
- purchases_flutter   # RevenueCat
- intl (format durations/dates)
- freezed_annotation + freezed (optional for immutable models)

## Error handling & edge cases
- Active session exists on another project when starting a new timer -> prompt to stop existing
- Manual entry validation (negative, non-numeric)
- Project deletion with sessions -> soft delete or cascade; recommend archive instead of hard delete
- Over-goal progress: visually cap bar at 100% with overage badge
- Timezone/DST changes -> UTC storage
- App killed during active session -> safe due to persisted startUtc

## Analytics & privacy
- No PII; all data on device
- Optional analytics can be added later; ensure privacy policy is included for store submission

## Testing strategy
- Unit tests
  - Time aggregation (sessions -> totals)
  - Timer start/stop logic and single active session invariant
  - Free vs Premium gating
- Widget tests
  - Progress bar rendering at edge values (0%, 100%, >100%)
  - Project list interactions
- Integration tests
  - Happy path: create project, run timer, stop, verify progress
  - Purchase flow (mocked)

## Build, CI, and release
- Use `flutter_flavorizr` or manual flavors (dev/stage/prod) to separate ad unit IDs
- CI (optional): run `flutter test` on PRs; format/lint checks
- Store assets: app icons, splash
- App Store & Play Console configs for IAP and Ads

## Milestones
1) M1 – Core data & UI (no monetization)
  - Project CRUD, sessions (manual + timer), progress bars
2) M2 – Polishing
  - UX polish, colors, archive, empty states, accessibility
3) M3 – Monetization
  - IAP (premium), ads in Free, gating for 3 projects
4) M4 – Hardening & release
  - Tests, migrations, store metadata, privacy policy

## Acceptance criteria
- Free users can create up to 3 projects, see banner ads; premium removes these limits
- Timer and manual entries both increase project progress accurately
- App persists data locally and survives restarts and phone sleep
- One active session at a time enforced
- Clear, colorful progress visualization per project

## Phased build steps (1–8)

1) Bootstrap the app
- Create the Flutter project; add deps: flutter_riverpod, go_router, isar, isar_flutter_libs, isar_generator, build_runner, purchases_flutter, google_mobile_ads, intl.
- Add theme.dart and app_router.dart; wrap runApp with ProviderScope in main.dart.
- Done when: app builds and shows a placeholder Projects page.

2) Data layer and models
- Define Isar models: Project and Session (UTC fields as specified).
- Implement repositories: project_repo.dart (CRUD + aggregates), session_repo.dart (timer/manual ops).
- Optional: seed a couple of debug projects.
- Done when: you can list projects from local DB.

3) Core state providers
- projects_ctrl.dart: expose projects with derived progress.
- timer_ctrl.dart: start/stop logic; enforce single active session invariant.
- Add small unit tests for aggregation and the invariant.
- Done when: providers compile and tests pass.

4) Projects list UI (wire existing designs)
- Hook Projects page to controllers; add colorful rough progress bar.
- Add FAB to create project; simple edit form (name, goal hours) with keyboard dismiss on tap-out.
- Done when: create projects and see progress update. (Done)

5) Manual entry + sessions (Done)
- Manual entry dialog (HH:MM) on Projects list row wired to SessionRepo.addManualEntry.
- ProjectsController watches Session changes; bar updates automatically.
- Display uses compact format (XhYm), and progress bar fill was tweaked for accurate visual ratio.
- Done

5b) Timer indicators (Done)
- Add per-project visual affordances:
  - Per-row active indicator (“Running” badge) and stacked action icons: “+” (manual) and clock (opens stopwatch sheet).
  - Global floating timer chip when a session is active (Stop action).
- Keep it minimal; real timer controls landed in Step 6.
- Done

5c) Drag-to-reorder (Done)
- Add manual prioritization by dragging projects; persist order using a new `sortIndex` field
- Ensure non-archived projects are displayed sorted by `sortIndex`; added safe default (0) for legacy records
- Fixed ReorderableListView child keys and moved non-reorderable header/empty-state out of the list
- Done

6) Stopwatch (Option A) – Local-only (Done)
- Stopwatch sheet: Start/Pause/Resume/Stop/Save
- After Stop, show confirmation “Will add Xh Ym to <project>”; Save always enabled; show subtle “< 1m, keep going” hint when rounded minutes == 0
- Expanded sheet height (~80% of screen) to minimize accidental background taps
- Save creates a manual session entry (rounded to nearest minute); no DB-backed live session is maintained while running
- Acceptance: stopping then saving adds time and updates totals; sheet UX is clear and responsive

6b) Optional Option B – DB-backed live timer (Future)
- Persist active session startUtc in DB, rehydrate on app resume/restart, enforce single-active invariant globally
- Not planned for MVP; revisit if needed

7) Polish the core
- Colors/accessibility; larger tap targets; empty/first-run states.
- Archive instead of delete (hide from main list).
- Keep screen awake while stopwatch is visible.
- Done when: core UX feels smooth and obvious.

8) Monetization (RevenueCat) + gating + ads
- Initialize purchases_flutter; expose isPremium from CustomerInfo.entitlements.
- Gate project creation to 3 for Free; unlimited for Premium.
- Integrate Google Mobile Ads banner on Projects/Detail for Free; hide for Premium.
- Settings: “Go Premium” and “Restore purchases”.
- Done when: entitlement flips remove ads and limits instantly.

## Current status (Sept 2025)
- Projects list and detail implemented with Material 3 + rough style
- Manual entry dialog implemented; totals update live from session changes
- Stopwatch sheet (Option A) implemented: local-only Start/Pause/Resume/Stop/Save with rounded-minute confirmation and expanded height
- Sessions grouped by date (Today/Yesterday/Date) on Project Detail; delete supported
- Drag-to-reorder implemented and persisted via `sortIndex`; default added to avoid legacy init crashes
- Deprecated Color.value usage removed (now using toARGB32())

## Next step decision
- Implement keep-awake during stopwatch to prevent the device from sleeping while timing.
  - Add dependency: `wakelock_plus`
  - Enable wakelock when `StopwatchSheet` is shown and disable on dispose
  - Acceptance: Screen stays on while stopwatch is open; returns to normal afterward
- Follow-up: Add Archive action in project row/menu and hide archived from main list; optional Archived view


