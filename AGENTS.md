# STATION_CHIEF Agent Instructions

## Source-of-truth hierarchy
1. `docs/vertical-slice-brief.md` — implementation contract for the first playable prototype
2. `docs/gdd-overview.md` — distilled project vision and pillars
3. Topic docs under `docs/design/`, `docs/architecture/`, `docs/content/`, and `docs/production/`
4. Codebase conventions and existing implementation

## What to optimize for
- Prove the core fantasy quickly: discrepancy-based intelligence analysis under time pressure.
- Prefer a rough but playable vertical slice over broad but shallow feature coverage.
- Keep the UI diegetic. Avoid non-diegetic quest markers, hint overlays, or explicit contradiction callouts.
- Keep content data-driven. Narrative text should live in data/content files, not system logic.
- Separate simulation/time/event logic from UI wherever practical.

## Vertical slice guardrails
- Implement one authored case first: The Falcon Meeting.
- Required apps: Inbox, Nominals, Intercepts, Map, Staff tasking panel.
- Required systems: time progression, event scheduling, hidden truth state, branching outcomes, political capital.
- Do not expand into campaign systems, full terminal simulation, or broad procedural generation unless specifically asked.

## Done when
- A player can complete one 10–20 minute case end-to-end.
- They must manually infer a HUMINT/SIGINT contradiction.
- At least three outcomes exist with understandable consequences.
- Political Capital changes are reflected through the diegetic interface.
