# Simulation Model

## Slice requirement
The first build does not need a full autonomous world simulation. It needs a believable hidden truth model that can emit evidence on a timeline.

## Minimum hidden state
- Current truth location for relevant NPCs
- Relationship flags between case actors
- Pending event schedule
- Outcome resolution rules tied to player actions

## Core principle
The simulation should generate evidence; the UI should display it. Avoid blending the two layers together.
