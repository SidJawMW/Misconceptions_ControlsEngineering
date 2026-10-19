# Misconception 5: "The tools I'm using don't matter"

## Where You Are

You have a plant you trust, a requirement you understand, a loop with the real delay in it, and a controller block that handles the cases you would have had to build yourself.

What you do not have is gains that work, code on the robot, or anything a reviewer could read.

## The Takeaway

> It does not matter how good you are at control theory if your tools make design, test and deployment hard.

Tools are not a convenience. They are what let you apply what you know.

## What Is In This Folder

| File | What it is for |
| --- | --- |
| `M5_SpeedLoop.slx` | The closed loop, with the transport delay from module 3. This is what you tune. |
| `M5_SpeedController.slx` | The tuned controller on its own, discrete, in a subsystem. This is what you generate C from. |
| `setup_M5_parameters.m` | Motor, delay, driver limit, gains and requirements. |
| `run_M5_validation.m` | Simulates the loop and prints the requirement check. |
| `generate_M5_report.m` | Builds `M5_Toolchain_Report.html`. |
| `M5_ToolchainValidation.png` | The generated validation plot. |

Two of those files are generated, and your own runs overwrite them. The
copies shipped here were produced at the tuned gains, so they show the
passing case. The model itself ships **untuned**, so the first time you run
`run_M5_validation` you will get the failing response instead. That is not a
mismatch to worry about: it is the before picture, and you are about to fix
it.

## How To Run It

```matlab
cd misconception_5
run_M5_validation
generate_M5_report
```

Or click the module 5 shortcut on the Project tab.

## Work Through It In This Order

### 1. Tune it, without sweeping gains by hand

Open `M5_SpeedLoop.slx` and double-click `PID Controller`. It opens at `Kp = 0.65`, `Ki = 2.20` - the gains you have carried since module 1. Run it first and watch them fail now that the delay is back in the loop.

Then confirm the type is **PI** and click **Tune**.

PID Tuner linearizes the loop and hands you a starting point almost immediately. Take its default and simulate it:

```text
setting              Kp       Ki |    rise  settle     OS%   verdict
default           0.231    0.953 |   0.216   0.962    9.33   FAIL: settling
```

**It fails.** Settling time is 0.962 s against a limit of 0.80, and the preview plot gave no hint of it. That is not a defect in the tool — settling time to a 2 % band was never part of what you asked it to optimise. The requirement lives in your head and in this README. The tuner never saw it.

### 2. Now drag the slider the wrong way

The instinct is to pull **Transient Behavior** toward *More Robust*, or **Response Time** toward *Slower*. Try it:

```text
response time 3 rad/s    0.098    0.518 |   0.441   1.554    9.97   FAIL: rise, settling
response time 4 rad/s    0.156    0.722 |   0.311   1.219   10.03   FAIL: rise, settling, overshoot
```

Worse. Much worse.

With a delay in the loop, a sluggish controller does not settle gently — it sits outside the band for longer and misses rise time as well. **Go faster instead:**

```text
response time 8 rad/s    0.394    1.166 |   0.119   0.439    5.91   PASS
```

Aim for roughly `Kp = 0.35`, `Ki = 0.8` to `1.2`. The shipped model uses `Kp = 0.35`, `Ki = 0.80`.

> **A trap worth knowing about.** PID Tuner does not simulate your model — it **linearizes** it. A `Transport Delay` block only contributes to a linearization if its **Pade order** is greater than zero, and the default is **zero**. Leave it at the default and your delay silently disappears from the plant the tuner designs against; it will hand you gains for a loop that does not exist. The delay in this model is set to Pade order 3 so that cannot happen. Open the block and look, because this one costs people days.

### 3. Validate against the requirements

```matlab
run_M5_validation
```

This validates **the gains that are in the model** - yours, whatever you tuned them to - and prints them at the top so there is no doubt about what was tested. If its numbers disagree with the PID Tuner preview, that is a real difference and worth chasing: the tuner predicts from a linearization, while this simulates the full non-linear loop with the driver limit in it.

With the shipped `0.35 / 0.80` you get:

```text
Requirement            Achieved      Limit    Margin   Result
Rise time                0.166s     0.300s       45%     PASS
Settling time            0.509s     0.800s       36%     PASS
Overshoot                0.000%    10.000%      100%     PASS
Steady-state error       0.100%     2.000%       95%     PASS
Requested voltage        3.978V    12.000V       67%     PASS
```

The tool got you most of the way in seconds. You owned the last part, and you have a table that says so.

### 4. Extract the controller

Open `M5_SpeedController.slx`. Two inputs — commanded speed and measured speed — one subsystem, one output: the motor voltage command.

Three things about that boundary are deliberate:

**It is discrete, at 0.02 s.** The same rate as the embedded speed task. A continuous controller generates C wrapped in solver scaffolding; a discrete one at the real task rate generates the fixed-step loop an embedded team actually integrates.

**The output limit is inside it.** The `PID Controller` block's own `Limit output` setting, with clamping anti-windup, is part of the controller and so part of the generated code. There is no separate Saturation block to forget. If the limit sat outside this boundary, the `+/-12 V` ceiling would survive only as an unwritten assumption in somebody's head.

The `Driver Limit` inside the plant is a different thing and is deliberately *not* here. That one is the hardware's; this one is the controller knowing about it.

**There is no plant in it.** You are handing over a controller, not a simulation.

### 5. Generate C from that boundary

With Simulink Coder or Embedded Coder installed:

1. Single-click the `Speed Controller` subsystem to select it.
2. Right-click and choose **C/C++ Code**.
3. Choose the generate or build command for the selected subsystem.
4. Open the code generation report and read the step function.

You should be able to point at the error calculation, the integrator update and the clamp, and match each one to a block you reviewed.

What is **not** in that code: the encoder driver, the PWM interface, task scheduling, calibration storage, diagnostics, safety supervision. Code generation does not finish the robot. It removes manual translation risk from the controller algorithm and gives the team a traceable artifact.

### 6. Generate the evidence

```matlab
generate_M5_report
```

Your design review will not ask "does it work?" It will ask which model was tested, what gains were used, which requirements were checked, and what supports the answer. The report has four sections and nothing else, because those are the four questions:

| Section | The question it answers |
| --- | --- |
| Controller Summary | What was designed? |
| Validation Metrics | What did it do when it was run? |
| Model-Based Design Artifacts | Which models is that evidence drawn from? |
| Requirements Compliance | Does it meet the requirement, line by line? |

Every number in it is pulled from the model and the validation run rather than typed in. Change a gain, rerun, and the report changes with it — including the PASS and FAIL column, which is computed rather than written.

That is the whole argument. Not that the report is pretty, but that regenerating it is cheap enough to do on every change, so it never quietly goes stale.

## A Word About Python

Python is a strong general-purpose language, and a capable team can absolutely build a workflow that runs from requirements through modelling, tuning, test automation, code generation and verification.

The point is not that Python cannot do this. The point is that your team would be assembling, validating, documenting and maintaining that entire workflow themselves — and that maintenance is real, recurring work paid for out of the same budget as the engineering.

## And Finally: Agentic AI

Short version, because this is a glimpse rather than a demonstration.

Companies are **experimenting** with AI agents in engineering workflows. Not fully adopting — experimenting. An agent can read a model, run it, summarise results, draft documentation, propose tests, and in some cases build a model from a prompt.

What makes that useful is not the agent. It is that the artifacts are executable, structured and testable in the first place. An agent pointed at a folder of ad-hoc scripts and hand-written C can do far less, far less reliably.

And it does not change who is accountable. Requirements, assumptions, model validity, safety decisions, final review, hardware interpretation and release approval are all still yours. Module 4 made the same point from the other direction: asking an agent to recreate a PID controller from scratch spends effort on a solved problem and leaves you holding something nobody validated.

Good tools made you faster. They did not make you optional. The same will be true of this.

## Where This Leaves You

Across five modules you went from "I'll be tuning controllers all day" to something closer to the real job: clarifying requirements, building and validating models, respecting hardware constraints, accounting for sensing and software, reusing what is trusted, and producing evidence other people can act on.

That last part is not overhead. It is how engineering work becomes a product.

## Notes For Facilitators

Step 1 is the one that earns the module. Take the tuner's default, run it, and let the room see it fail — then let somebody suggest making it more robust before you show that going faster is the fix. The counterintuitive direction is what makes it stick.

Do not let step 5 become a code generation tutorial. The claim is narrow: a validated controller boundary reduces translation error and gives software teammates something concrete.

For the Agentic AI segment, play a short recording rather than demonstrating live, and keep the framing honest — this is what industry is starting to explore, not what it has settled on.
