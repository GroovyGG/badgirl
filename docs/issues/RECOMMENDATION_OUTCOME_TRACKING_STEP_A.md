## [Sub-issue A] Recommendation outcome tracking foundation / recommendation 结果追踪基础层

## Summary / 功能概述
**EN:** Add durable outcome-tracking fields and state transition timestamps for recommendations.  
**中文：** 为 recommendation 增加可持久化的结果追踪字段和状态流转时间。

## Scope / 范围
- Add tracking fields to `ExerciseRecommendation`:
  - `acceptedAt`
  - `skippedAt`
  - `completedAt`
  - `outcomeSignal` (`unknown | improved | persisted`)
  - `outcomeEvaluatedAt`
- Ensure action handlers update timestamps consistently:
  - accept -> `status=accepted`, set `acceptedAt`
  - skip -> `status=skipped`, set `skippedAt`
  - complete -> `status=completed`, set `completedAt`
- Keep `ExerciseLog` linkage intact for completed/replaced execution.

## Acceptance Criteria / 验收标准
- [ ] `ExerciseRecommendation` contains the new tracking fields.
- [ ] Status transitions write correct timestamps.
- [ ] Existing recommendation card actions still work.
- [ ] App launches and saves recommendations without schema crashes.

## Value / 价值
Provides a reliable event history for later quality analysis and tuning.
