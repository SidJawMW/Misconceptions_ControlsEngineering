# Five Misconceptions About Being A Controls Engineer

A hands-on workshop for fresh graduates and early-career control engineers.

Everything is built around one running example: the speed control loop for a brushed DC motor driving one wheel of a differential-drive floor robot — a robotic vacuum. You keep the same motor, the same requirement and the same loop for all five modules. What changes is how much of the real world you are allowed to ignore.

## Start Here

Open `ControlsMisconceptions.prj`. That loads the MATLAB project, puts every module on the path, and adds five shortcuts to the **Project** tab of the toolstrip.

Click the shortcut for the module you are working on. It:

- closes the previous module's models, so you never accumulate open windows,
- loads that module's parameters into the base workspace as `params`,
- moves you into the module folder, so `run_M*` scripts just work,
- opens that module's models.

Nothing simulates until you press play. You never need to `cd` anywhere or remember which setup script goes with which model.

To move from one misconception to the next, click the next shortcut. That is the whole workflow — there is nothing to close or clean up first.

Switching modules closes every other workshop model, **including any you have edited but not saved**. Those edits are discarded, and the command window names what went. That keeps one clean module on screen instead of a pile of half-tuned models from three exercises ago. If you want to keep an experiment, save it before you move on.

Work through the modules **in order**. Each one builds on the model and the gains you finished the previous one with.

| Module | The belief it takes apart | The takeaway |
| --- | --- | --- |
| [1](misconception_1/README_M1.md) | "I'll mostly be designing controllers" | You need a plant model first, and getting one is most of the work |
| [2](misconception_2/README_M2.md) | "I need to maximize control performance" | Faster is not free. Exceeding your requirement writes a stricter one for somebody else |
| [3](misconception_3/README_M3.md) | "The simulation is reality" | Controls is a system-level discipline: be curious about disturbances, noise and model-vs-reality gaps |
| [4](misconception_4/README_M4.md) | "I'll build everything from scratch" | Reuse trusted, validated components. Spend your time on what is unique to your project |
| [5](misconception_5/README_M5.md) | "The tools I'm using don't matter" | Produce validated, reviewable, traceable evidence |

Each module folder contains its own `README_M*.md`. Read that first — it tells you which model to open and in what order.

## What You Need

**MATLAB and Simulink** open, simulate and run every model in modules 2 to 5, and the starter and first-principles models in module 1. One block in the workshop comes from an add-on: the LTI System block in `M1_Solution_ComparePlants` needs Control System Toolbox.

Four add-ons are needed only for specific interactive steps, and every one of them has a fallback that keeps the module's point intact:

| Step | Needs | Prerequisite | Without it |
| --- | --- | --- | --- |
| Module 1, identify the plant from bench data | System Identification Toolbox | — | A representative plant is already loaded into the LTI System block, so the comparison still works |
| Module 1, open `M1_Solution_ComparePlants` at all | **Control System Toolbox** | — | **No fallback.** The identified plant is an LTI System block, which is a Control System Toolbox block. Use `M1_FirstPrinciplesMotor` instead, which needs only Simulink |
| Module 5, **Tune** on the PID Controller block | Simulink Control Design | Control System Toolbox | The tuned gains ship in `setup_M5_parameters.m`; you lose the live tuning, not the result |
| Module 5, `generate_M5_report` | Simulink Report Generator | MATLAB Report Generator | The script detects this and writes plain HTML with the same four sections |
| Module 5, generate C from the controller | Simulink Coder | MATLAB Coder | The controller model still opens, so the implementation-boundary discussion works without generating anything |

Embedded Coder is optional on top of Simulink Coder. It is not needed to generate code, but it adds the code-to-model traceability links that make "point at this line, find the block it came from" a single click.

Note that the **Tune** button on a PID Controller block requires Simulink Control Design, not Control System Toolbox. The block itself is core Simulink; only automatic tuning is licensed. Control System Toolbox is needed as Simulink Control Design's prerequisite rather than for anything the workshop calls directly.

The models are shipped built and ready to run. You do not need to generate anything before you start.

**There are no Scope blocks.** Signals are logged by name and read in the **Simulation Data Inspector**, which keeps every run so you can compare one tuning against the last. Open it from the Simulink toolstrip after you simulate.

If you do not want to use the project, every module still works standalone: `cd` into its folder and run the scripts named in its README.

## The Requirement, Carried Through Every Module

```text
Step command        0 to 10 rad/s
Rise time           < 0.30 s
Settling time       < 0.80 s
Overshoot           < 10 %
Steady-state error  < 2 %
Motor voltage       within +/-12 V        (enforced from module 3 onward)
```

This block is on the canvas of every model in the workshop. It is the one annotation the models carry; everything else that needs saying is in these READMEs, so that nothing on screen competes with the thing being pointed at.

**There are no Saturation blocks on any loop.** From module 3 onward the `+/-12 V` ceiling lives inside the `DC Motor` subsystem as `Driver Limit`, because that is where it physically is: the battery and the H-bridge cannot deliver more, whatever the control law asks for. What a *controller* does about saturation — limiting its own output, anti-windup — belongs to the controller, and from module 4 the `PID Controller` block owns it. Keeping those two apart is what makes module 4's windup demonstration work.

## The Gains, Module By Module

Tracking these tells the story of the whole workshop on its own:

```text
Module 1   Kp = 0      Ki = 0       where the starter model begins: you tune it
Module 1   Kp = 0.65   Ki = 2.20    where hand-tuning lands, and the solution model
Module 2   Kp = 0.65   Ki = 2.20    your own starting point, then pushed too far
Module 3   Kp = 0.65   Ki = 2.20    deliberately not retuned, and now failing
Module 4   Kp = 0.65   Ki = 2.20    unchanged; this module is about the controller block, not the gains
Module 5   Kp = 0.65   Ki = 2.20    what the model opens with - still failing, now with the delay back
Module 5   Kp ~ 0.35   Ki ~ 0.80    where PID Tuner takes you, and what goes to code generation
```

## Folder Layout

```text
ControlsMisconceptions.prj   the MATLAB project - start here
README.md                    this file
VOICEOVER.md                 spoken script for the opening and the close
DC motor.png                 master copy of the motor block icon
misconception_1/ .. _5/      the workshop modules
shortcuts/                   what the toolstrip shortcuts run
authoring/                   scripts that generate the models (facilitators only)
```

Inside a module folder you will find, at most:

- `README_M*.md` — what to do and why
- `setup_M*_parameters.m` — every number the models use
- `*.slx` — the Simulink models
- `run_M*.m` — runs the models and saves the plot
- `*.png` — the expected result, so you can check yourself
- `DC motor.png` — the picture on the motor block's face, which Simulink reads from disk every time it draws the icon. Leave it where it is; if it goes missing the block shows `? ? ?` instead of a motor.

Simulink writes build output (`slprj`, `*_rtw` folders, `.slxc` caches) into these folders as you work. None of it is source and none of it is in the project; delete it freely.

## Status

All five modules reflect the September 2026 check-in and the October 2026 model change requests: a requirements block on every canvas, the voltage limit modelled inside the motor driver rather than as a loop Saturation block, module 1 starting from zero gains with the motor equations on the canvas, module 3 plotting the encoder signal so the delay is visible, module 4 showing one controller at a time, and a four-section validation report in module 5.

Still outstanding from the check-in, and not file work: the workshop graphics (Sid to send Brian a list), the "everything a controls engineer does" slide for the module 1 to 2 transition, and the short recorded agentic-AI session that replaces the Quanser Cube demo.

## For Facilitators

You can deliver this without the original author. Each module README ends with a short **Notes For Facilitators** section covering what to demonstrate, where the discussion usually stalls, and what to do if a toolbox is missing.

[`VOICEOVER.md`](VOICEOVER.md) is the spoken script for the two parts that are pure narration — the opening before module 1 and the close after module 5 — with timings, alternate cold opens and a cut-down order if you are running late.

The models are generated from scripts in [`authoring/`](authoring/README.md) rather than drawn by hand, so layout and annotations stay consistent and any change can be reapplied across all five modules. Learners never need to go in there.
