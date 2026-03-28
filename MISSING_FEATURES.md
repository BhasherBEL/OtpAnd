# Missing Features: maas-rs vs OpenTripPlanner

OtpAnd now queries **maas-rs** (RAPTOR algorithm) instead of OpenTripPlanner.
The following features are not yet available in maas-rs and are degraded or disabled.

---

## Journey Planning

| Feature | OTP | maas-rs | Impact |
|---------|-----|---------|--------|
| Multi-result journey planning | ✅ | ✅ | — |
| Arrival-time routing (`latestArrival`) | ✅ | ❌ | Always routes by departure time, even when "Arrive by" is selected |
| Cursor-based pagination (prev/next page) | ✅ | ❌ | All results returned at once; "Load more" controls are hidden |
| Profile mode preferences (reluctance, wait reluctance, …) | ✅ | ❌ | Routing ignores profile cost parameters |
| Per-mode toggles (bus/tram/rail/ferry enable/disable) | ✅ | ❌ | All transit modes are always considered |
| Walking-only journeys via A* | ✅ | ⚠️ | Currently only RAPTOR (transit) is queried; walk-only results are not returned |
| Search window / time range | ✅ | ❌ | No equivalent; maas-rs returns the optimal result for the given departure |

## Leg Information

| Feature | OTP | maas-rs | Impact |
|---------|-----|---------|--------|
| Leg geometry (encoded polyline) | ✅ | ❌ | Map renders straight lines between stops instead of actual paths |
| Leg distance (meters) | ✅ | ❌ | CO₂ emissions are always shown as 0 |
| Intermediate stops (stop-by-stop breakdown) | ✅ | ❌ | Transit leg detail view shows no intermediate stops |
| Real-time departure/arrival times | ✅ | ❌ | All times are scheduled only; auto-update is never triggered |
| Leg ID (for individual leg refresh) | ✅ | ❌ | `fetchLegById` is not supported; `UpdateLegs` is a no-op |
| `interlineWithPreviousLeg` flag | ✅ | ❌ | Always false |
| Service date (`YYYYMMDD`) | ✅ | ❌ | Always null |

## Trip & Route Metadata

| Feature | OTP | maas-rs | Impact |
|---------|-----|---------|--------|
| GTFS trip ID | ✅ | ❌ | Placeholder ID used (`maas:<shortName>_<headsign>`) |
| Trip short name | ✅ | ⚠️ | Set to route short name (best approximation) |
| GTFS route ID | ✅ | ❌ | Placeholder ID used (`maas:<shortName>`) |
| Route color / text color | ✅ | ❌ | Route colors fall back to mode defaults |

## Saved Plans

| Feature | OTP | maas-rs | Impact |
|---------|-----|---------|--------|
| Saved plan re-parsing from DB | ✅ | ⚠️ | Plans saved from maas-rs reload correctly but without route info (no GTFS IDs to look up in local DB) |

---

## Tracking

These limitations should be addressed by implementing the corresponding features in maas-rs:

- `maas-rs#XX` — Leg geometry (polyline encoding)
- `maas-rs#XX` — Leg distance
- `maas-rs#XX` — Intermediate stops
- `maas-rs#XX` — Real-time data integration
- `maas-rs#XX` — Arrival-time routing
- `maas-rs#XX` — Expose GTFS IDs for trips and routes
- `maas-rs#XX` — Route colors from GTFS
- `maas-rs#XX` — Cursor-based pagination
