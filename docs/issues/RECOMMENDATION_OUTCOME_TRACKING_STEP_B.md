## [Sub-issue B] Repeated-issue improvement signal / 重复问题改善信号判定

## Summary / 功能概述
**EN:** Evaluate whether target problems in recommendations improved or persisted in subsequent sessions/reflections.  
**中文：** 判断 recommendation 对应的问题在后续 session/reflection 中是改善还是持续存在。

## Scope / 范围
- Add analytics methods to compute:
  - accepted rate
  - completion rate
  - improvement signal by recommendation (`improved | persisted | unknown`)
- Define v1 rule:
  - Use recommendation `targetProblem` as keyword.
  - Scan next N sessions’ reflections after source session.
  - If keyword appears in reflection/problem fields -> `persisted`
  - If not found and enough future reflections exist -> `improved`
  - If not enough future context -> `unknown`
- Provide aggregate summary endpoint:
  - counts/rates for improved/persisted/unknown

## Acceptance Criteria / 验收标准
- [ ] Can compute accepted/completion rates from persisted data.
- [ ] Can evaluate recommendation outcome signal using the v1 rule.
- [ ] Can return aggregate signal distribution for dashboards/tuning.
- [ ] No regression in existing suggestion/recommendation flows.

## Value / 价值
Creates a measurable feedback loop to tune recommendation quality over time.
