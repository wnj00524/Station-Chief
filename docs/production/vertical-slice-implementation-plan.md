# STATION_CHIEF Vertical Slice Implementation Plan (The Falcon Meeting)

## 1) Objective and scope lock

This plan delivers one playable 10–20 minute case, **The Falcon Meeting**, and only the systems needed to prove the core fantasy:
- manual discrepancy detection (HUMINT vs SIGINT),
- time pressure,
- action under uncertainty,
- diegetic consequences via Political Capital and debrief messaging.

### In scope
- Desktop shell with dock + top bar status
- Inbox, Nominals, Intercepts, Map, Staff tasking panel
- Real-time clock and scheduled evidence arrivals
- Hidden truth state and outcome resolution
- 3+ decision outcomes with delayed/credible consequences
- Data-authored case content for Falcon only

### Explicitly out of scope
- Campaign progression/meta loop
- Procedural case generation beyond reusable schema scaffolding
- Non-diegetic hints, contradiction callouts, or quest markers
- Full terminal simulation

---

## 2) Product behavior targets (vertical-slice acceptance)

The build is considered done when:
1. Player can complete Falcon end-to-end in ~10–20 minutes.
2. Player must use at least three apps before making a judgment call.
3. Contradiction is inferable from cross-app evidence but never auto-labeled.
4. Time progression and event deadlines materially affect outcomes.
5. At least three outcomes exist (success, partial, failure/defensive).
6. Political Capital updates are visible in diegetic desktop UI.

---

## 3) Implementation architecture (modular + data-driven)

## 3.1 Layering model

### Content layer (authored data)
- Case timeline, cast, locations, inbox threads, intercept schedule, staff tasks, and decisions authored as data.
- No narrative strings hardcoded in simulation logic.

### Simulation layer (deterministic runtime)
- Clock/tick progression
- Event scheduling (intercepts, deadlines, task completions)
- Hidden truth state used for resolution
- Decision resolver using current minute + task completion flags + case rules

### Presentation layer (desktop apps/UI)
- Reads public sim state only
- Renders app views and actionable controls
- Emits user intents (open app, queue task, choose decision)

This separation keeps authored content reusable and prevents UI from encoding game truth directly.

## 3.2 Data contracts (minimum for Falcon + future reuse)

Propose formalized data contracts for:
- `CaseDefinition`
- `NpcRecord`
- `LocationRecord`
- `InboxThread`
- `InterceptEvent`
- `StaffTaskTemplate`
- `DecisionOption`
- `OutcomeRule`

Even if implemented in plain JS first, define a schema file (or JSDoc typedefs) so additional handcrafted cases can be added with low code changes.

## 3.3 Simulation ruleset for Falcon

- At case start, player receives HUMINT claim in Inbox.
- SIGINT intercepts unlock on timeline and appear in Intercepts (and map context).
- Staff tasks generate delayed Inbox reports.
- Decision availability gated by “meaningful app usage” (3+ apps).
- Final decision resolves through outcome rule set using:
  - chosen decision,
  - time elapsed,
  - relevant completed tasks,
  - Falcon hidden truth.

No rule should directly emit “this is the contradiction.” The system only emits evidence.

---

## 4) Proposed folder/file structure

```text
src/
  data/
    schemas/
      caseSchema.js               # case data contract validators/typedefs
    cases/
      falconMeeting.js            # authored slice case
  sim/
    clock.js                      # time progression
    eventBus.js                   # sim event distribution
    scheduler.js                  # generic timeline event scheduler
    caseEngine.js                 # orchestrates case runtime state
    decisionResolver.js           # branching outcome rules
    stateProjection.js            # hidden state -> public UI state mapping
  ui/
    app.js                        # desktop bootstrap + wiring
    desktop/
      topBar.js                   # clock/connection/PC display
      dock.js                     # app launcher
      windowManager.js            # window/view orchestration (lightweight)
    apps/
      inboxView.js
      nominalsView.js
      interceptsView.js
      mapView.js
      staffPanelView.js
  content/
    copy/
      falcon-debriefs.md          # optional narrative source synced to data

tests/
  sim/
    decisionResolver.test.mjs
    scheduler.test.mjs
    caseEngine.timeline.test.mjs
  content/
    falconCase.validation.test.mjs

docs/
  production/
    vertical-slice-implementation-plan.md
```

Notes:
- Keep `falconMeeting.js` as the single authored case for this phase.
- `scheduler.js` and `decisionResolver.js` isolate logic likely to grow without forcing UI rewrites.

---

## 5) Milestone breakdown

## Milestone 0 — Contract lock (0.5 day)
- Freeze slice acceptance criteria and non-goals.
- Confirm Falcon hidden truth + evidence cadence + outcome matrix.
- Define minimal data schema/typedef spec.

## Milestone 1 — Simulation foundation (1–2 days)
- Implement/normalize clock + scheduler + event bus integration.
- Refactor/confirm case engine lifecycle: start, tick, scheduled dispatch, task completion, resolve, stop.
- Add public-state projection boundary so UI cannot access hidden truth directly.

**Exit criteria:** deterministic timeline behavior with test coverage.

## Milestone 2 — Case content pass (1 day)
- Author Falcon content against schema:
  - inbox seed,
  - intercept timeline,
  - nominals/location records,
  - staff task templates,
  - decision options + branching outcomes.
- Add data validation tests for completeness and references.

**Exit criteria:** Falcon loads and resolves with no hardcoded fallback strings in sim logic.

## Milestone 3 — Diegetic desktop UX integration (1–2 days)
- Ensure required apps are accessible and legible in dock/window flow.
- Render timestamps, recurring names, and location hints across apps.
- Surface Political Capital + clock in top bar continuously.

**Exit criteria:** player can cross-reference evidence across all required apps without hints.

## Milestone 4 — Staff tasking + consequence loop (1 day)
- Finalize task queue UX + delayed report insertion into Inbox.
- Ensure task outcomes influence decision resolver where intended.
- Add Home Office debrief panel and end-state feedback through diegetic interface only.

**Exit criteria:** judgment call feels consequential and tied to evidence quality + timing.

## Milestone 5 — Balancing + polish + test hardening (1 day)
- Tune decision deadline and task durations for 10–20 minute session feel.
- Add/adjust tests for edge timing and late decisions.
- Remove any accidental non-diegetic guidance.

**Exit criteria:** repeatable playthroughs yield understandable success/partial/failure branches.

---

## 6) Risks and assumptions

## Key risks
1. **Over-signposting risk:** UI might accidentally reveal contradiction too explicitly.
   - Mitigation: review copy and labels for inference-only phrasing.
2. **Timing brittleness:** case could be too short/long or outcomes feel arbitrary.
   - Mitigation: deterministic timing tests + quick balance table for durations/deadlines.
3. **Layer leakage:** UI may start depending on hidden truth fields.
   - Mitigation: enforce public state projection and test against forbidden fields.
4. **Content/logic coupling:** branching text may drift into engine code.
   - Mitigation: keep debrief/outcome copy in case data content.
5. **Scope creep:** temptation to add second case/campaign scaffolding.
   - Mitigation: milestone gating tied to single-case acceptance only.

## Assumptions
- Current repo baseline (clock, event bus, engine, Falcon data seed) is acceptable as starter architecture.
- Visual fidelity can remain rough so long as desktop workflow is clear and diegetic.
- One deterministic authored case is sufficient to validate the core fantasy before wider systems.

---

## 7) Recommended first PR scope (small, high-leverage)

**PR goal:** Lock simulation/content contracts for Falcon and de-risk branching behavior before UI expansion.

Include in first PR:
1. Add/normalize case schema definitions (or JSDoc typedefs + validator).
2. Split decision resolution into `sim/decisionResolver.js` with focused tests.
3. Add scheduler unit tests for intercept/task/deadline timing determinism.
4. Validate Falcon case data references (location IDs, task IDs, decision IDs).
5. Keep UI changes minimal (only wiring required due to refactor).

**Why this first:**
- Establishes a stable gameplay core and prevents UI-first rework.
- Preserves data-driven architecture from the start.
- Creates fast confidence loops via deterministic tests.

---

## 8) Definition of done checklist

- [ ] Falcon case is fully playable start-to-resolution in one session.
- [ ] Required apps all contribute meaningful evidence.
- [ ] No non-diegetic hints/quest markers/auto contradiction labels.
- [ ] 3+ outcomes with clear Political Capital consequences.
- [ ] Outcome shown via diegetic desktop/debrief, not external overlay.
- [ ] Simulation logic separated from presentation.
- [ ] Content authored in data files, not embedded in core logic.
- [ ] Automated tests cover scheduling and decision branching edge cases.
