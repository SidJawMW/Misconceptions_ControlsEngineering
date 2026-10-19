# AGENTS.md — Controls Engineering Workshop Builder

## Purpose

You are helping build a workshop for fresh graduates and early-career control
engineers stepping into industry. The workshop uses a single-speed control
loop for a brushed DC motor — the drive motor of a differential-drive floor
robot (e.g., a robotic vacuum) — as the running example. Each stage of the
walkthrough is used to correct one misconception a new controls engineer
commonly holds.

The five misconceptions, from the perspective of the control engineer, are:

1. "I'm going to spend the majority of my time designing controllers."
2. "I need to maximize control performance."
3. "I'm a controls engineer so I only need to learn controls."
4. "I'm going to write all my code from scratch."
5. "The tools I'm using don't matter."

The narrative frame throughout: a fresh graduate has just joined a robotics
company and is working through the design of the speed control loop for a
brushed DC motor on a differential-drive vacuuming robot.

## Core Workflow — Brainstorm First, Then Build

For **each of the five misconceptions**, follow this exact sequence. Do not
skip ahead or batch multiple misconceptions together unless explicitly told
to.

1. **Brainstorm before building.** Before creating any Simulink model,
   MATLAB script, or other artifact, discuss with me what we want that
   misconception's module to demonstrate. Ask what I want the agent to do —
   e.g., what specific concept, failure mode, or contrast we want to
   illustrate using the DC motor speed loop, what the "aha moment" should be
   for the fresh graduate, and what form the artifact should take.
2. **Do not assume scope.** Do not generate Simulink models, MATLAB code, or
   supporting files until I've confirmed what to build for that
   misconception.
3. **Build only after alignment.** Once I confirm the direction, build the
   artifact(s) for that misconception only.
4. **Move to the next misconception** only after I indicate we're done with
   the current one, repeating the brainstorm-then-build sequence.

## Artifact Requirements

Every artifact produced (Simulink models, MATLAB scripts/live scripts,
supporting functions, documentation) must be:

- **Clean** — well-organized model hierarchy/subsystems, consistent naming,
  no leftover debug blocks or dead code, tidy signal routing.
- **Professional** — suitable to hand to a colleague or use in a paid
  workshop; proper labeling, titles, units, and annotations on all models
  and plots.
- **Standalone** — each artifact must run independently without requiring
  unpackaged dependencies, hidden setup steps, or tribal knowledge. Include
  any needed initialization/setup script alongside the model.
- **Usable by two different audiences:**
  - **Workshop facilitators** — other engineers should be able to pick up
    the materials and deliver the workshop themselves without needing the
    original author present.
  - **Self-paced learners** — students should be able to work through the
    materials on their own after the live session, with enough in-model/
    in-script commentary that the misconception and its resolution are
    clear without a live narrator.
- Include brief in-artifact documentation (comments, annotations, or a short
  accompanying README/markdown per misconception) explaining: the
  misconception, what the artifact demonstrates, and the takeaway.

## Context to Ground the Example

- **Plant:** brushed DC motor, single speed control loop (not full
  position/cascade control unless a misconception module specifically
  calls for it).
- **Application:** differential-drive floor robot for household tasks
  (e.g., vacuuming) — use this context to motivate real constraints
  (battery/power limits, cost-sensitive hardware, embedded compute,
  noisy/imperfect sensing, safety around furniture/pets/people, duty
  cycle, etc.) when relevant to a given misconception.
- **Audience:** a fresh graduate, newly hired at a robotics company,
  encountering these realities for the first time.

## Interaction Rules

- Treat each of the five misconceptions as its own mini-module with its own
  brainstorm → confirm → build cycle.
- If my brainstorm answers are ambiguous or leave a reasonable design choice
  open, state your assumption briefly and proceed — but the initial
  question of "what should this module demonstrate" must always be asked,
  not assumed.
- Keep deliverables scoped to what supports the specific misconception being
  addressed — avoid scope creep into unrelated controls topics.
