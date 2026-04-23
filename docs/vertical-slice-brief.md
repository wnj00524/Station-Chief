# Vertical Slice Brief

## Goal
Build a **single-session playable vertical slice** that proves the core fantasy of STATION_CHIEF:

> The player operates from a diegetic desktop, receives conflicting intelligence, manually cross-references evidence, makes a judgment call under time pressure, and experiences meaningful consequences.

Target session length: **10–20 minutes**.

## In scope
- Desktop shell
- Inbox app
- Nominals / Database app
- Intercepts app
- Map app
- Staff tasking panel
- Real-time clock progression
- Hidden ground-truth state
- One HUMINT vs SIGINT discrepancy
- At least 3 player response options
- Delayed consequences
- Political Capital change

## Out of scope
- Full campaign
- Full procedural case generation
- Advanced terminal parser
- Rich personal desktop features
- Deep faction simulation beyond what the slice needs

## Playable scenario: The Falcon Meeting
Premise:
- A trusted informant claims they are at a cafe awaiting a meeting with a local official.
- SIGINT metadata places their phone near the airport instead.
- The player must determine whether the informant is lying, compromised, or intentionally separating themselves from their phone.

Hidden truth for v1:
- The informant is compromised.
- The message is bait.
- The real handoff is occurring near the airport.
- Rival faction HIA is involved.

## Required player actions
At least 3 of the following:
- Trust and proceed
- Assign analyst to verify
- Task surveillance near airport
- Abort or delay meeting

## Branch outcomes
### Best
Player identifies the airport angle and reacts effectively.
- Useful intel gained
- Lead on official/HIA link strengthened
- Political Capital +2

### Partial
Player verifies first and reacts too slowly.
- Some intel lost
- Opportunity degraded
- Political Capital +0 or +1

### Failure
Player trusts the cafe claim and commits there.
- Real event missed
- Asset exposure or embarrassment
- Political Capital -2

### Defensive but costly
Player aborts without exploiting the lead.
- Trap avoided
- No gain achieved
- Political Capital -1 or 0

## Acceptance criteria
- Player uses at least 3 apps meaningfully before deciding.
- Contradiction is inferable but not explicitly highlighted.
- Time pressure matters.
- At least 3 outcomes exist.
- Outcome is delivered through the diegetic interface.
- Content is data-driven and reusable.
