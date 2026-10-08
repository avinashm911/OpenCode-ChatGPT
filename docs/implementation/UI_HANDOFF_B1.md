# UI_HANDOFF_B1 — trial, clock and entitlement surface for screens

Date (UTC): 2026-10-08. Source: B1 (`TrialService`, `BackendBundle` facade).
No widgets or ARB were changed in B1. Screens call these members on the
`BackendBundle` (via `CompanyScope` holders or the startup outcome's backend).

## Facade queries (all on `BackendBundle`, per company id string)

| Member | Inputs | Outputs | Screen use |
|---|---|---|---|
| `entitlementState(companyId)` | company id | `trialActive` / `graceActive` / `expired` / `denied` | banner + feature gating |
| `daysLeft(companyId)` | company id | whole days of full function left (ceil); 0 when expired/denied | banner count ("9 days left") |
| `reminderDue(companyId)` | company id | true only during grace | daily expiry reminder trigger |
| `clockWarning(companyId)` | companyId | true when the latest observation reported rollback | non-alarming clock notice |
| `exportBackupAllowed(companyId)` | company id | true in every state except denied | export/share/backup buttons stay enabled when expired |
| `guardCompanyOpen(companyId:, deviceNowMs:, actor:, eventId:)` | ids + device ms | `Result<ClockObservation>` (ok, or typed `diagnostic` err when the rollback audit row itself fails) | **must be called from the shell's `openCompany`** (presentation/shell/niav_shell.dart:105) on every company open/switch — currently navigation-only and NOT yet wired (UI-series work) |

## Typed error codes (plain English)

| Code | Meaning | UI text suggestion |
|---|---|---|
| `entitlement` | trial expired or install denied: the write was refused, nothing was saved | "Trial expired — read, export and backup still work" / "This install is denied" |
| `diagnostic` | clock-guard audit row failed (DB fault); observation still kept | log only; do not alarm the user |

## States and enums

- `EntitlementState`: trialActive (full function) → graceActive (full function + daily reminder, 10 days) → expired (read-only + export + backup, data never deleted) → denied (denylist hit, everything refused except nothing — export also refused).
- Trial length 3 months from install start; end date = start + 3 calendar months UTC, day clamped (PROPOSAL pending owner tick §10).
- `ClockObservation`: `trustedNowMs` (max of device time and persisted mark), `rolledBack` flag, `lastSeenMs`.

## Screen IDs that will call these (UI/UX spec)

Trial/banner surface (home + startup status), company switch (`openCompany` guard call), billing forms (surface `entitlement` refusal without losing the draft — the backend already preserves drafts by aborting before effects), export/share/backup buttons (enabled when `exportBackupAllowed`).

## Notes for the UI series

- Never invent remaining-days math on the UI side: always call `daysLeft`.
- Rollback warnings must never block billing (backend guarantee; keep the notice dismissible).
- The `denied` state needs its own screen copy (owner + legal input pending on wording).
