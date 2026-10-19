# Misconception 1: "I'm going to spend the majority of my time designing controllers"

## Where You Are

You have just joined a robotics company that builds a differential-drive floor robot — think robotic vacuum. Your first assignment is the speed control loop for one brushed DC motor driving one wheel.

You open the starter model. There is a PI controller, there is a list of requirements, and there is a block called `Plant` that does nothing at all.

So here is the first question of the workshop:

> What exactly are you going to tune, and what do you need before tuning means anything?

By the end of 0this module you will have answered it yourself. The short version: your first job is not turning knobs. It is producing a plant model you trust, a test scenario you can run, and requirements you can measure against.

## The Requirements You Are Working To

```text
Step command        0 to 10 rad/s
Rise time           < 0.30 s
Settling time       < 0.80 s
Overshoot           < 10 %
Steady-state error  < 2 %
Motor voltage       within +/-12 V
```

You will find this block on the canvas of every model in the workshop, including every model in later modules. It never changes. What changes is how much of the real world is standing between you and it.

The `+/-12 V` line is the battery and the motor driver. Nothing in this module comes close to it — the tuned loop peaks around 6.5 V — so it is listed rather than enforced here. Module 2 is where you find out what happens when you ask for more.

Current limits, disturbance rejection, gearbox effects and vehicle-level dynamics are deliberately left out for now. They arrive in later modules, one at a time.

## What Is In This Folder

| File | What it is for |
| --- | --- |
| `M1_Starter_PI_Only.slx` | Where you begin. A PI controller built from basic blocks with **both gains at zero**, dashboard sliders for `Kp` and `Ki`, and an empty `Plant` block. |
| `show_M1_BenchData.m` | Loads the bench-test record and plots it. Run this before opening the System Identification app. |
| `M1_FirstPrinciplesMotor.slx` | The brushed DC motor derived from physics, open loop, so you can see the equations as blocks. |
| `M1_Solution_ComparePlants.slx` | The closed loop, with a `Plant Select` switch so you can compare the first-principles motor against an identified model. The identified branch is an **LTI System** block, so you can drop your own estimate straight into it. Needs Control System Toolbox. |
| `setup_M1_parameters.m` | Every number the models use, in one place. |
| `M1_PRBSBenchData.mat` | The bench-test record: commanded voltage and measured wheel speed. |
| `M1_PRBSBenchData_Plot.png` | The generated plot of the bench experiment. |

The models are shipped built and ready to run.

**Open the Simulation Data Inspector** to see signals. There are no Scope blocks anywhere in this workshop — logged signals go to the Data Inspector, which keeps every run so you can compare one tuning against the last.

## Work Through It In This Order

### 1. Open `M1_Starter_PI_Only.slx` and resist the sliders

Look at what you have been given. A controller with `Kp = 0` and `Ki = 0`. Requirements. Dashboard sliders, parked at the far left, that are begging to be dragged.

The gains start at zero deliberately. Nobody hands you a tuned loop on your first day, and nudging somebody else's answer is not tuning.

Now open the `Plant` block. It is empty - an input port, an output port, and nothing at all between them.

So drag the sliders. Watch nothing happen — not because the model is broken, but because there is nothing on the other side of the controller to respond.

Ask yourself what moving `Kp` could possibly tell you here. Nothing, and that is the point. Without a plant, a controller is an opinion.

### 2. Open `M1_FirstPrinciplesMotor.slx` and read the physics

Look inside `DC Motor (First Principles)`. The two equations are written on the canvas above the blocks, and every wire below is one term of them:

```text
L di/dt = V - R*i - Ke*w     (electrical)
J dw/dt = Kt*i - b*w         (mechanical)
```

The top row builds armature current. `Kt` turns that current into torque. The mechanical row turns torque into speed. Three gains return right to left: `R*i` is the resistive drop, `Ke*w` is back-EMF, `b*w` is viscous friction.

This is one way to get a plant model, and when you can do it, it is a good way. You understand every parameter and you can ask what happens if any of them changes.

### 3. Ask when first principles will not be available to you

**"I'll work somewhere big, they'll already have a model."** Often true, and it helps less than you would hope. A large programme usually does have a model — detailed, nonlinear, time-varying, validated against flight or test data, and built by a team whose job was fidelity.

That model was not built for control design. It may be too slow to run in a loop, too stiff to linearize, too detailed to reason about, or simply not have the inputs and outputs you need. Turning it into something you can design against — by linearizing it, by reducing it, or by running system identification *on the model itself* — is still your work.

Inheriting a model moves the starting line. It does not remove the job.


It often will not be. You may not know the physics, the supplier may not publish the parameters, friction and contact effects may refuse to be modelled cleanly, or you may simply not have the weeks it would take.

That is not a failure. It just means you get your plant model a different way.

### 4. Run the bench experiment

```matlab
show_M1_BenchData
```

This is an open-loop bench run on one wheel motor: a pseudo-random binary voltage command applied to the motor, with the wheel speed recorded off the encoder.

Three details are deliberate, and all of them matter more than they look.

**The speed trace is visibly steppy, and that is the encoder.** Speed is derived by counting encoder edges over one sample interval, so it can only ever be a multiple of `2*pi / (countsPerRev * sampleTime)`. With the robot's 1000 count/rev encoder sampled at 200 Hz that step is **1.26 rad/s** — on a signal that only swings about 11 rad/s. On top of it sits edge jitter and electrical pickup. That staircase is not a plotting artifact; it is the resolution you bought.

**The bench samples faster than the control loop.** The rig runs at 200 Hz; the speed controller in modules 3 to 5 runs at 50 Hz. Faster sampling gives identification more bandwidth, and costs resolution: a shorter counting window means fewer edges per sample, so a coarser speed step. The same encoder gives the controller a 0.31 rad/s step and the bench a 1.26 rad/s one. If your bench data looks worse than your control loop's feedback, this is usually why.

**The voltage command is clean; only the speed carries noise.** That is not laziness. The command is generated in software, so you know it exactly, and every standard identification method assumes exactly that: `y = G(q)u + H(q)e`, with the noise at the output. Corrupt the input and you have an errors-in-variables problem, which those methods are not built for and which biases the answer. If you ever *do* have a noisy input measurement, that is a different and harder problem — look up total least squares before you reach for `tfest`.

**The test runs at about 11 rad/s, not 30.** The robot drives its wheels at around 10 rad/s, and a model fitted three times above its operating point is fitted to a regime the controller never visits. Exciting near the operating point is one of the cheapest ways to get an identification result you can actually use.

Open `M1_PRBSBenchData_Plot.png` before you fit anything, and answer these from the plot alone:

- Does the input keep exciting the motor over the whole test, or does it go quiet?
- Does the output visibly respond to input changes?
- Is this open-loop data, or is a controller already in the loop?
- Which trace is the plant input, and which is the plant output?

The script deliberately keeps your workspace small. It does not hand you motor current, noise-free speed, or internal simulation states, because a real bench test would not hand you those either.

### 5. Identify a model from the data

```matlab
show_M1_BenchData
systemIdentification
```

If `systemIdentification` is not available in your release, open the app from the Apps tab or run `ident`.

**Import the experiment.** Choose to import data from the workspace and select `M1_sysid_data`. Name the data set `M1_motor_prbs_data`.

If `M1_sysid_data` does not appear, import the raw arrays instead:

```text
Data type    Time-domain signals
Input        M1_voltage_V
Output       M1_speed_radps
Time vector  M1_time_s
Sample time  M1_Ts_s
Input name   Motor voltage
Output name  Wheel speed
```

**Look at the data.** Open the time plot and confirm the input is the PRBS command and the output is the speed response. Keep the whole record; this data is close enough to zero-mean for the purpose.

**Estimate a model.** Choose transfer-function estimation, set it to continuous time, use 2 poles and 0 zeros, and estimate. Rename the result `M1_identified_motor_tf`.

**Validate it.** Open the model-output comparison plot against `M1_motor_prbs_data`. The simulated output should follow the measured speed. If you have time, look at the residuals too — they should not show a strong pattern that tracks the input.

**A word on the fit percentage.** You should see roughly **92 %**. Resist two opposite instincts: do not celebrate it, and do not try to fix it.

Where the missing 8 % comes from is worth working out, because the arithmetic is simple and it generalises. The fit is approximately

```text
fit  =  100 * (1 - noise_std / signal_std)
```

Your speed signal has a standard deviation of about 5.4 rad/s. The encoder contributes roughly 0.44 rad/s of error — quantization plus jitter — and 0.44 / 5.4 is about 8 %. The number is not mysterious. It is the sensor, showing up in the result.

**So a better fit is something you buy, not something you tune.** Halve the encoder error and you get about 96 %. The lever is the part number, the sample rate, or a longer averaging window — not the estimation options in the app.

And notice what the noise did *not* cost you. Check the DC gain of your identified model against the first-principles value: it agrees to better than half a percent. Noisy data has given you a model that is perfectly good enough to design a controller against. A fit percentage is a measure of how well the model explains *this record*, not of how useful the model is.

Real bench data can fit worse still, and then the cause is usually unmodelled physics rather than noise: gearbox backlash and compliance, friction that is not simply proportional to speed, motor driver deadband, temperature drift over a long test, load changing as the robot crosses a floor. None of those exist in this model. When your fit comes back at 70 % on real hardware, that number is telling you which of them you left out.

**Model structure is a choice, and it is iterative.** You picked 2 poles and 0 zeros because a DC motor is second order and you knew that going in. You will not always be so lucky. In practice you try a structure, look at the fit and the residuals, and try another: more poles, a zero, a process model with a delay term, a state-space model of a given order. The app makes that cheap, which is the point of using it.

**Export it** to the workspace. Then, if you want to check it yourself:

```matlab
compare(M1_sysid_data, M1_identified_motor_tf)
[num, den] = tfdata(M1_identified_motor_tf, "v")
```

`num` and `den` are exactly what you would type into a Transfer Fcn block.

### 5b. How this is done when you have no app

The walkthrough above is clean because the app is doing a lot of work for you. Plenty of teams identify models without it, and you should recognise the methods when you see them.

**Step or bump tests.** Drive a step and read the model straight off the response. For a first-order speed loop, the steady-state value gives you the DC gain `K`, and the time to reach 63 % of it gives you the time constant `tau`. That is a `K/(tau*s + 1)` model in two measurements, and it is often enough to tune a PI controller. Most practising engineers can do this on a scope without writing any code.

**Reading a second-order response.** If the response overshoots, the overshoot fraction gives you the damping ratio and the period of the ringing gives you the natural frequency. Standard formulas turn those into a transfer function.

**Frequency sweeps.** Drive sine waves at a series of frequencies, record amplitude ratio and phase shift at each, and plot the result. You get a measured Bode plot directly, which is what you actually need for loop shaping and stability margin. Slower than a PRBS test, but it makes the frequency response explicit instead of inferred.

**Least squares in a few lines of code.** Write the discrete difference equation with unknown coefficients, stack your logged samples into a regressor matrix, and solve with backslash. This is what the toolbox is doing underneath, and implementing it once is a good way to stop treating identification as magic.

**Ask someone.** Motor suppliers publish `R`, `L`, `Kt`, `Ke` and rotor inertia. A datasheet plus a measurement of the load inertia often beats an identification experiment, and takes an afternoon rather than a week.

The reason to know these is not nostalgia. On a bench at 2 a.m. with a scope and no toolbox licence, a bump test still works.

### 6. Compare the two plants in closed loop

Open `M1_Solution_ComparePlants.slx`. Double-click `Plant Select` to toggle it:

- top input — `DC Motor (First Principles)`
- bottom input — `Identified Plant (System Identification)`

The model already contains a worked identified plant, so you can do this comparison even if you skipped the app workflow.

### 7. Now, finally, tune

The sliders labelled `Kp` and `Ki` are bound directly to the gain blocks inside `PI Controller`. Use this sequence:

1. **Reset.** `Kp = 0.10`, `Ki = 0.00`. Run it. The response is slow and settles short of 10 rad/s. Proportional-only control leaves steady-state error — see it rather than take it on faith.
2. **Raise `Kp`.** Try `0.30`, run, then `0.65`, run. The response gets quicker. Stop at about `0.65`.
3. **Add `Ki`.** Try `0.50`, run. The final speed moves toward the command but settles slowly. Try `1.20`, then `2.20`. At `2.20` you should meet the steady-state error requirement without wrecking overshoot or settling time.
4. **Check against the requirements.** Rise time under 0.30 s, settling under 0.80 s, overshoot under 10 %, steady-state error under 2 %.
5. **Switch plants and re-check.** Run the same gains against the other plant path. If they only work on one of them, your modelling assumptions are doing more of the work than your tuning is. That is worth knowing now rather than on hardware.

The supplied baseline is:

```text
Kp = 0.65
Ki = 2.20
```

These are plain, honest PI gains, not an optimised controller. They exist so you have a reference response, not a target to beat.

## Logged Variables

| Model | Variable |
| --- | --- |
| `M1_Starter_PI_Only` | `M1_starterSpeed` |
| `M1_FirstPrinciplesMotor` | `M1_openLoopSpeed` |
| `M1_Solution_ComparePlants` | `M1_closedLoopSpeed` |

## What You Should Take Away

Count what you actually did in this module. You clarified a requirement, worked out what plant information was missing, chose a modelling approach, designed a bench experiment, prepared data for identification, fitted and validated a model, and only then checked a closed-loop response against measurable criteria.

Exactly one of those steps was controller tuning.

That ratio is not an artifact of this workshop. In industry, controls engineers help shape concepts, size components, write and negotiate requirements, build models, design tests, support verification and validation, investigate anomalies, and explain tradeoffs to mechanical, electrical, software, manufacturing and product teams. Controller design matters. It is one part of turning a system idea into a product that works.

## Notes For Facilitators

The first-principles model is not presented as the superior option. It is one route to a plant model; the PRBS workflow is the other, and the choice between them is usually made by schedule and available information rather than by preference.

The most productive moment in this module is usually step 1 — letting the room reach for the sliders and then discovering there is nothing behind them. Do not rush past it.

If you are short on time, the identified plant is already built into `M1_Solution_ComparePlants.slx`, so steps 4 and 5 can be demonstrated rather than performed.
