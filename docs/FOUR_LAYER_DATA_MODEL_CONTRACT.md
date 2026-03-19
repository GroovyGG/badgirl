# Four-layer Data Model Contract (v1)

This document freezes model boundaries for:
- Session event layer
- Reflection review layer
- Recommendation output layer
- Exercise execution log layer

## 1) Session event layer

Existing model:
- `TrainingSession` (acts as `Session`)

Current `sessionType` allows multiple values. Product-level `game | training` can be enforced at UI/service level first, then narrowed later if needed.

## 2) Reflection review layer

Existing model:
- `SessionReflection`

One reflection belongs to one `TrainingSession`.

## 3) Recommendation output layer

New models:
- `Exercise` (catalog of executable actions)
- `ExerciseRecommendation` (system-generated recommendation entries)

Status enum (string values):
- `suggested`
- `accepted`
- `skipped`
- `completed`

## 4) Execution log layer

New model:
- `ExerciseLog` (actual user-performed exercise record)

`ExerciseLog` may be linked to:
- an `ExerciseRecommendation` (when user follows recommendation)
- a `TrainingSession` (execution context)
- an `Exercise` (what was actually performed)

## Relationship summary

- `TrainingSession` 1 : 1 `SessionReflection` (existing)
- `TrainingSession` 1 : N `ExerciseRecommendation`
- `TrainingSession` 1 : N `ExerciseLog`
- `Exercise` 1 : N `ExerciseRecommendation`
- `Exercise` 1 : N `ExerciseLog`
- `ExerciseRecommendation` 1 : N `ExerciseLog`
- `MovementTarget` 1 : N `Exercise` (optional link; enables target-related suggestion generation)

## Notes

- Recommendation and execution are intentionally split to avoid conflating “suggested” with “done”.
- This contract keeps existing session/reflection flows intact while adding recommendation and execution capabilities incrementally.
