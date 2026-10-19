 # Misconception 3: "The simulation is reality"

## Where You Are

Your speed loop works. It met every requirement in simulation, and you were right to be pleased with it.

Then it goes on hardware, and it rings.

Nothing is broken and nobody made a mistake. The difference is that in your model the feedback was a wire. On the robot it is a measurement that takes time to arrive.

## The Takeaway

> Controls is a system-level discipline.

You cannot be handed a list of everything that will differ between your model and your hardware, because it depends on the industry, the product and the programme. What you can do is stay curious about three things:

- **Disturbances** — what pushes on the plant that you did not put in the model
- **Noise** — sensor noise, electrical pickup, quantization, anything that corrupts what you measure
- **Model-vs-reality gaps** — where your plant model stops being true

This module shows exactly **one** of those, in the simplest form it takes. That is deliberate. Watch what a single ordinary number does to your response, then imagine the dozens that exist on a real programme.

## The One Effect: Transport Delay

```text
Transport delay   0.060 s
```

Sixty milliseconds, from the moment the wheel turns to the moment your controller can act on it. On a small robot that is unremarkable: a 20 ms control task, filtering inside the encoder driver, and a hop across a bus.

What it costs you is phase. Your loop crosses over at about 13.2 rad/s, and a 60 ms delay at that frequency is **45 degrees** — out of the 86 degrees of phase margin the ideal loop had. More than half your margin, spent on a number nobody thought to tell you.

Delay does not make your plant weaker. The gain is untouched. It makes your information **old**, and a controller acting on old information overcorrects.

## What Is In This Folder

| File | What it is for |
| --- | --- |
| `M3_SimulatedLoop.slx` | The loop with direct feedback. A `Transport Delay` block sits beside it, fed a copy of the speed and terminated, so you can see it before it does anything. |
| `M3_MeasuredLoop.slx` | The same loop with the delay wired into the feedback path. Same gains. |
| `setup_M3_parameters.m` | Motor, driver limit, delay and requirements. |
| `run_M3_comparison.m` | Runs both, prints the metrics, saves the comparison plot. |
| `M3_SimulatedVsMeasured.png` | The generated plot. |

The `+/-12 V` ceiling lives in this module rather than module 2, because it is a physical reality rather than a requirements consequence. You will not find a Saturation block on the loop: it is inside the `DC Motor` subsystem, as `Driver Limit`, because that is where it physically is. Neither controller in this module gets near it.

## How To Run It

```matlab
cd misconception_3
run_M3_comparison
```

Or click the module 3 shortcut on the Project tab.

**Open the Simulation Data Inspector** to see the signals. There are no Scope blocks anywhere in this workshop — the Data Inspector keeps every run, so you can overlay the ideal and delayed responses and step through them with cursors. A scope shows you the run you just did and forgets the one before it.

## Work Through It In This Order

### 1. Confirm the loop still behaves

Open `M3_SimulatedLoop.slx` and run it. Motor speed goes straight back to the summing junction. With `Kp = 0.65` and `Ki = 2.20` it does what module 1 promised: 2.1 % overshoot, settled in 0.45 s.

### 2. Look at the block sitting outside the loop

There is a `Transport Delay` below the forward path. It receives a copy of the motor speed and its output is terminated, so right now it changes nothing. Open it and read the delay time.

Then ask where 60 ms would come from on a real robot, and whether anyone would have mentioned it to you.

### 3. Wire it in

1. Delete the feedback line from `DC Motor` to the minus input of `Speed Error`.
2. Delete the line from `Transport Delay` to its terminator, and delete the terminator.
3. Route the motor speed through `Transport Delay`, and its output back to `Speed Error`.

`M3_MeasuredLoop.slx` already contains exactly this, so you can check your work.

### 4. Run them side by side

```matlab
run_M3_comparison
```

```text
Case             Rise   Settle  Overshoot      SSE  Max Req V
Simulated       0.148    0.449       2.08     0.01       6.50
Measured        0.060    0.603      35.70     0.01       7.82
```

**Overshoot goes from 2 % to 36 %.** The requirement was 10 %.

Your controller did not change. Your plant did not change. One number in the feedback path changed, and the design no longer meets its requirement.

Two things are visible in the plot, and they are different things:

- The measured trace **starts 60 ms late**. That is the delay itself.
- Then it **rings to 13.6 rad/s**. That is what the delay costs you.

### 4a. A question worth asking

Look closely at *which* signal is plotted for the measured case. It is `Measured speed` — the encoder signal — not the motor's true speed.

That matters more than it sounds. The delay here is in the **feedback** path. If you plot the motor's true speed instead, the trace starts moving the instant the step lands, with no visible delay at all:

```text
signal                                    first moves
true motor speed                             0.102 s
measured speed, what the controller sees     0.163 s
```

A feedback delay does not hold the motor back. It makes the controller's information **old**, and a controller acting on old information overcorrects. The ringing *is* the delay, showing up where the delay actually does its damage.

So why plot the measurement? Because on the robot it is the only thing you have. There is no probe on the shaft reporting true speed to you — there is an encoder, and it is late. The plot shows you what you would actually see on the bench.

### 5. Do not retune

You will want to. Don't — not here. This module is about noticing the delay, not tuning around it. Module 4 picks up the tuning.

## Requirements

Unchanged from modules 1 and 2:

```text
Step command        0 to 10 rad/s
Rise time           < 0.30 s
Settling time       < 0.80 s
Overshoot           < 10 %
Steady-state error  < 2 %
Requested voltage   within +/-12 V
```

## What You Should Take Away

The lesson is not "always account for delay". It is that the loop you are responsible for extends past the blocks you drew. Sensing, timing, mechanics, software scheduling and actuation all sit inside it, and most of them were decided by people who were not thinking about your phase margin.

Nobody will come looking for the person who set the task period when the robot overshoots on the test rig. They will come to you.

## Notes For Facilitators

Step 3 is worth doing live even though the finished model is supplied. Physically dragging one block into the feedback path makes the point that nothing about the controller changed.

If the room wants more effects — encoder quantization, filtering, sampling — that is the right instinct and the wrong moment. Say so out loud: there are dozens, this is one, and the point is what one does. Adding more would make the plot messier without making the argument stronger.

The phase arithmetic is the line that lands with a technical audience: 45 degrees of your 86, spent on 60 milliseconds.

Step 4a is worth the two minutes even though it looks like a detour. "Why doesn't the output start 60 ms late?" is the first question a sharp participant asks, and the answer - a feedback delay ages your information rather than delaying your plant - is one of the few things in this module that is genuinely counterintuitive. If nobody asks, ask it yourself.
