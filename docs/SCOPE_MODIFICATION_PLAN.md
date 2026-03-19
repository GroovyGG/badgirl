# Bad Girl — Scope Modification Plan: General + Badminton Only

**Goal:** Treat the app as **general activity + badminton only**. Other sports (climbing, tennis, table tennis) will not be expanded; simplify UI, data, and copy accordingly.

---

## 1. Data & Schema

| Change | Detail |
|--------|--------|
| **Sports** | Keep `Sport` model for schema compatibility. In seed data: **deactivate** or **remove** `climbing`, `tennis`, `table_tennis`. Only **badminton** remains as an explicit sport; "general" is represented by `sport_id == nil` (no new model). |
| **Movement targets** | No schema change. Filter everywhere to targets where `sport == nil` (general) or `sport.code == "badminton"`. Seed data already has general + badminton targets; remove any seeds for other sports if present. |
| **Metric definitions** | Same filter: only general (`sport == nil`) or badminton metrics. Remove or deactivate metric definitions for other sports. |
| **Training sessions / goals / calendar** | No schema change. App logic and UI assume only two contexts: **general** (no sport) and **badminton**. |

**Optional (simplification):** Add a small `AppConfig` or constant: `supportedSportCodes = ["badminton"]` and `isGeneralTraining(sport: Sport?)` → `sport == nil`. Use in all queries and filters.

---

## 2. Persistence & Seeding

| Change | Detail |
|--------|--------|
| **PersistenceController seed** | Insert only **badminton** in `sports`. Either do not insert climbing/tennis/table_tennis, or insert them with `isActive = false` so they never show in pickers. |
| **Movement targets & metrics** | Seed only general + badminton. Remove seeds for other sports. |

---

## 3. UI: Log Flow (记录)

| Change | Detail |
|--------|--------|
| **Session type / domain** | Keep "训练域" (general vs sport-specific vs match vs recovery). When user picks **sport-specific** or **比赛**, do not show a **sport picker** — treat as badminton by default (single option). Either hide the sport step or show a single fixed "羽毛球" chip. |
| **Movement targets** | Filter to `sport == nil || sport?.code == "badminton"`. Same for metric definitions in the metrics step. |

---

## 4. UI: Home, Calendar, Progress, Library

| Area | Change |
|------|--------|
| **Home (今日)** | Suggestions already come from movement targets; filter to general + badminton targets only. No UI change for "sport" unless we currently show sport labels — then show only "基础训练" or "羽毛球". |
| **Calendar (训练历)** | When planning or viewing sessions, filter to general + badminton. Session type labels: show "羽毛球" / "比赛" / "基础训练" etc., no other sport names. |
| **Progress (趋势)** | Sport filter pills: remove "climbing", "tennis", "table_tennis". Show only **全部** and **羽毛球** (or "基础" if useful). Default to badminton. |
| **Library (更多)** | **Movement targets:** filter list to general + badminton only. **Metric definitions:** same. **Sport list:** either hide the "sport" grouping or show a single "羽毛球" section + "基础训练". |

---

## 5. Copy & Strings

| Change | Detail |
|--------|--------|
| **App description / README** | State explicitly: "General activity and badminton only; other sports are not supported in this app." |
| **In-app** | Where we mention "sport" or "运动项目", phrase as "羽毛球" or "基础训练" only. Avoid "选择运动" with multiple sports; use "训练类型" / "羽毛球专项" as needed. |

---

## 6. Suggestion Engine & Queries

| Change | Detail |
|--------|--------|
| **TrainingSuggestionEngine** | When fetching `allTargets`, pass only targets where `sport == nil || sport?.code == "badminton"`. Same for sessions (already per-user; no change if we never log other sports). |
| **All @Query / FetchDescriptor** | Where "sport" is used (e.g. Progress dashboard sport filter, Library filters), restrict to `nil` or `badminton`. |

---

## 7. Implementation Order (Recommended)

1. **Seed data** — PersistenceController: only badminton active; only general + badminton targets and metrics.
2. **Constants / helpers** — e.g. `supportedSportCode = "badminton"`, filter helpers for targets and metrics.
3. **Log flow** — Remove or fix sport picker (badminton-only); filter targets and metrics to general + badminton.
4. **Progress** — Sport filter: only 全部 + 羽毛球.
5. **Library** — Filter movement targets and metric definitions to general + badminton; simplify sport grouping.
6. **Home / Calendar** — Ensure any sport-aware labels or filters use badminton-only logic.
7. **Copy & README** — Update to "general activity and badminton only".

---

## 8. Out of Scope (No Work)

- Adding new sports (climbing, tennis, etc.).
- Multi-sport switching or "add sport" flows.
- Schema changes for new sport types.

---

## Summary

| Layer | Action |
|-------|--------|
| **Data** | Only badminton (+ general) in seeds; filter all targets/metrics to `sport == nil \|\| sport?.code == "badminton"`. |
| **UI** | No multi-sport picker; single "羽毛球" or "基础" where needed; sport filter pills reduced to 全部 + 羽毛球. |
| **Copy** | App is "general activity + badminton only". |
| **Code** | Centralize sport filtering via constants or helpers; apply in Log, Progress, Library, Home, Calendar, SuggestionEngine. |
