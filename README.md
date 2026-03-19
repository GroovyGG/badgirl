# Bad Girl

Personal iOS app for tracking **general activity** and **badminton** only — log sessions, record metrics and reflections, get rule-based “what to train next” suggestions, and view progress over time. Other sports are not supported. Supports Apple Watch / Apple Health for heart rate and activity when worn, with optional iCloud sync across devices.

**Built with Swift 6 · SwiftUI · SwiftData · HealthKit · CloudKit.**

---

## Table of Contents

1. [Tech Stack](#tech-stack)
2. [Getting Started](#getting-started)
3. [Tabs & Features](#tabs--features)
4. [Project Structure](#project-structure)
5. [Data & Schema](#data--schema)
6. [HealthKit & CloudKit](#healthkit--cloudkit)

---

## Tech Stack

| Layer        | Technology |
|-------------|------------|
| Language    | Swift 6    |
| UI          | SwiftUI    |
| Persistence | SwiftData (on-device SQLite, CloudKit sync optional) |
| Health      | HealthKit (read-only: heart rate, active energy, steps, sleep, exercise time) |
| Sync        | CloudKit (iCloud container for cross-device SwiftData sync) |
| Charts      | Swift Charts |
| Min OS      | iOS 17+    |

---

## Getting Started

- **Xcode:** Open `Bad Girl/Bad Girl.xcodeproj` in Xcode. Build and run (⌘R).
- **Simulator:** Select any iPhone simulator as the run destination.
- **Device:** Connect an iPhone, select it as the run destination, and ensure **Signing & Capabilities** uses your Apple Developer team. HealthKit and CloudKit require a paid [Apple Developer Program](https://developer.apple.com/programs/) account for real-device use.
- **First run:** Grant Health access when prompted; data is stored locally (and in iCloud if CloudKit is enabled).

---

## Tabs & Features

| Tab      | Purpose |
|----------|--------|
| **今日** (Home) | Today’s date, rule-based training suggestion card, today’s goals, quick-log button, recent sessions, health snapshot strip. |
| **记录** (Log)  | Entry point to open the 7-step log flow (data source → type → date/time → targets → metrics → scores → reflection). Saves as sheet; supports “Apple Watch recorded” vs “fully manual” input. |
| **训练历** (Calendar) | Month grid with session dots, day detail (logged + planned sessions), plan a session for a future date. |
| **趋势** (Progress) | Metric trend cards (Swift Charts), weak areas (targets with low quality score), RPE trend, Apple Health strip (e.g. sleep). |
| **更多** (Library) | Movement targets, muscle groups, metric definitions, HealthKit status, app info. |

---

## Project Structure

```
Bad Girl/
├── Bad_GirlApp.swift          # App entry, modelContainer + HealthKit env
├── ContentView.swift          # Root → RootTabView
├── Models/                    # SwiftData @Model classes (15 types)
│   ├── Sport, TrainingDomain, MuscleGroup, MovementTarget, ...
│   ├── TrainingSession, SessionTarget, SessionMetricEntry, ...
│   ├── PlannedSession, PlannedSessionTarget, DailyGoal, ...
│   └── HealthSnapshot, SessionReflection
├── Persistence/
│   └── PersistenceController.swift   # ModelContainer, seed data, CloudKit config
├── HealthKit/
│   └── HealthKitManager.swift        # Authorization + read stubs (heart rate, energy, steps, sleep, exercise)
├── Services/
│   └── TrainingSuggestionEngine.swift # Rule-based “what to train next”
├── Extensions/
│   ├── Color+Sport.swift
│   └── Date+Helpers.swift
├── Views/
│   ├── RootTabView.swift
│   ├── Home/                  # HomeView, SuggestionDetailView
│   ├── Log/                   # LogSessionView, steps, SessionDetailView
│   ├── Calendar/              # CalendarView, DayDetailView, PlanSessionView
│   ├── Progress/              # ProgressDashboardView, MetricDetailView
│   ├── Library/               # LibraryView, movement targets, muscle groups, metrics
│   └── Shared/                # SessionCardView, RPESliderView, MetricChartCardView
└── Bad Girl.entitlements      # HealthKit + iCloud CloudKit
```

---

## Data & Schema

- **Scope:** App supports **general** (no sport) and **badminton** only; other sports are not shown or expanded.
- **Sports & domains:** `Sport`, `TrainingDomain` — badminton (and others) and training context (e.g. general, sport-specific, match, recovery).
- **Training content:** `MovementTarget`, `MovementTargetMuscle`, `MetricDefinition` — what to train and what to measure.
- **Sessions:** `TrainingSession`, `SessionTarget`, `SessionMetricEntry`, `SessionReflection` — one log per session with targets, metrics, and reflection.
- **Planning:** `PlannedSession`, `PlannedSessionTarget`, `DailyGoal`, `DailyGoalTarget` — calendar and daily goals.
- **Health:** `HealthSnapshot` — Apple Health data attached to a session or standalone.

Seeded on first launch: default sports (e.g. badminton, climbing, tennis), training domains, sample movement targets, and metric definitions.

---

## HealthKit & CloudKit

- **HealthKit:** Read-only access for heart rate, active energy burned, step count, sleep analysis, and Apple exercise time. Used when logging with “Apple Watch recorded”; otherwise session is logged without Health import. Requires `NSHealthShareUsageDescription` in Info and `com.apple.developer.healthkit` entitlement; real device requires Apple Developer Program.
- **CloudKit:** Optional iCloud sync via SwiftData (`ModelConfiguration.cloudKitDatabase = .automatic` for production). Uses container `iCloud.com.GroovyGG.Bad-Girl`. Same iCloud account on multiple devices syncs data. Requires CloudKit entitlement and container in the developer account.
