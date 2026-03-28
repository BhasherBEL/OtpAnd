# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

All Flutter commands must be run via `devenv shell --`:

```bash
# Run the app
devenv shell -- make          # flutter run
devenv shell -- make apk      # flutter build apk

# Restart ADB if needed
make adb      # sudo adb kill-server && sudo adb start-server  (plain sudo, no devenv)

# Lint
devenv shell -- flutter analyze

# Generate launcher icons
devenv shell -- flutter pub run flutter_launcher_icons
```

## Tests

All Flutter commands must be run via `devenv shell --`:

```bash
# Run all tests
devenv shell -- flutter test

# Run a specific test file
devenv shell -- flutter test test/utils_test.dart
devenv shell -- flutter test test/objects/plan_test.dart

# Run with verbose output
devenv shell -- flutter test --reporter=expanded

# Run a single test by name pattern
devenv shell -- flutter test --name="getEmissions"
```

**IMPORTANT: Always run `devenv shell -- flutter test` before and after making changes.** All tests must pass.

### Test structure

```
test/
  helpers/test_factories.dart     # Shared factory functions (makeLeg, makePlan, etc.)
  utils_test.dart                 # lib/utils.dart — formatting, colors, icons
  utils/
    extensions_test.dart          # lib/utils/extensions.dart
    maps_test.dart                # lib/utils/maps.dart — Haversine, polyline
  objects/
    plan_test.dart                # Plan model (pure logic only)
    leg_test.dart                 # Leg model — emissions, colors, intermediateStops, frequency
    place_test.dart               # Place, DepartureArrival, EstimatedTime
    stop_test.dart                # Stop model
    route_test.dart               # RouteMode, RouteInfo
    location_test.dart            # Location model
    search_history_test.dart      # SearchHistory model
    timed_stop_test.dart          # TimedStop, PickupDropoffType
  blocs/
    plan_bloc_test.dart           # PlanBloc (uses MockPlanRepository via mocktail)
    plans_helpers_test.dart       # PlansPageInfo, PlansQueryVariables helpers
  api/
    plan_maas_test.dart           # maasSecondsToIso, maasRouteTypeToMode, parseMaas*, buildRawLeg
```

### What is NOT tested (and why)

- **DAOs** (`lib/db/crud/`): require `sqflite` and `getDownloadsDirectory()`, which need device/OS integration. Use a real device or emulator to verify DB changes.
- **`lib/api/gtfs_maas.dart`** (GTFS sync): requires a live maas-rs server. Test manually by running the app with a reachable maas-rs instance.
- **`lib/api/plan_maas.dart`** — pure parsing helpers are fully unit-tested (see `test/api/plan_maas_test.dart`); only the `fetchMaasPlans()` network call requires a live server.
- **Legacy dead code** — `lib/api/plan.dart` (OTP journey API) and `lib/api/gtfs.dart` (OTP GTFS sync) are no longer called; they remain in-tree but untested.
- **Pages and widgets** (`lib/pages/`, `lib/widgets/`): require a full Flutter widget tree and would need mocking of many singletons. Test manually on device.
- `StorePlan` / `DeletePlan` BLoC events: call `PlanDao().loadAll()` with `unawaited()`, which requires the device DB. These are tested end-to-end on device.

### Adding new tests

- Use `package:` imports (enforced by `always_use_package_imports` lint rule)
- Use factory helpers from `test/helpers/test_factories.dart` to construct test objects without DB access
- Never call `Plan.parse()`, `Leg.parse()`, or `Place.parse()` in unit tests — these hit the DB/StopDao/RouteDao
- Construct model instances directly with their constructors instead
- Use `mocktail` for mocking (no codegen required)

## Architecture

OtpAnd is a Flutter MaaS (Mobility as a Service) app for public transport planning, backed by **maas-rs** (Rust RAPTOR + A* engine, port 3000) and OpenStreetMap. It targets Android (Gradle + Flutter).

> **Migration note**: The app was originally backed by OpenTripPlanner (OTP). The legacy API files `lib/api/plan.dart` and `lib/api/gtfs.dart` remain in-tree but are no longer called. See `MISSING_FEATURES.md` for features not yet available from maas-rs.

### Layer overview

| Layer | Path | Notes |
|---|---|---|
| Entry point | `lib/main.dart` | Initializes DB, config, caches, then launches `HomePage` |
| Navigation | `lib/pages/homepage.dart` | 3-tab bottom nav: Journeys / Stops / Settings |
| Pages | `lib/pages/` | One file per screen |
| Widgets | `lib/widgets/` | Reusable UI components (map, route icons, pickers…) |
| BLoC | `lib/blocs/` | State management via `flutter_bloc` — `plan/` and `plans/` |
| API | `lib/api/` | GraphQL calls to maas-rs (`plan_maas.dart`, `gtfs_maas.dart`); legacy OTP files are dead code |
| Database | `lib/db/` | SQLite via `sqflite` (schema v10); one DAO per entity |
| Models | `lib/objects/` | Plain Dart data classes (no codegen) |
| Utils | `lib/utils/` | Colors, extensions, GNSS, route colors, import/export |

### State management

BLoC is used for async/remote state. Simple UI state lives directly in `StatefulWidget`s. There are two BLoC families:
- `PlanBloc` — handles a single in-progress journey query to maas-rs (RAPTOR); `updateLegs` is a no-op since maas-rs legs carry no IDs
- `PlansBloc` — manages the list of saved plans from SQLite

### Data flow for journey planning

1. User picks origin/destination (stop search from local SQLite cache, map picker, contact, or favourite)
2. `PlanBloc` fires an event → calls `lib/api/plan_maas.dart` → fires RAPTOR GraphQL query to maas-rs
3. Response is parsed into `Plan`/`Leg`/`Location` objects (`lib/objects/`) via `parseMaasPlan()`
4. UI renders itineraries; user can save a plan → persisted via `PlanDao` using `buildRawLeg()` for DB serialization

### Data flow for startup GTFS sync

1. App starts → `main()` ensures default profile, warms in-memory caches from SQLite
2. `OTPApp.initState()` calls `checkAndSyncMaasGtfsData()` (non-blocking, rate-limited to once/23h)
3. `lib/api/gtfs_maas.dart` queries `gtfsStops` + `gtfsAgencies` from maas-rs
4. Results are batch-inserted into SQLite (`stops`, `agencies`, `routes`, `agencies_routes` tables)
5. In-memory caches reload → stop search in from/to picker becomes available

### Database

SQLite database stored at `/Downloads/app.db` (device path). DAOs each expose `loadAll()` / CRUD methods. Entities: `plans`, `profiles`, `routes`, `stops`, `agencies`, `favourites`, `search_history`, `directions`. Startup preloads all entities into memory; UI reads from in-memory lists, not directly from DB.

### Configuration

`lib/objects/config.dart` + `Config().init()` at startup loads app-level settings from `shared_preferences`. Key settings: `maas_url` (default `http://192.168.0.211:3000`), `otp_url` (legacy, unused).

### Linting

`analysis_options.yaml` enforces `flutter_lints` plus strict mode (`strict-casts`, `strict-raw-types`, `strict-inference`). Also enforces `single_quotes`, `always_use_package_imports`, `always_declare_return_types`, `avoid_void_async`, `unawaited_futures`.
