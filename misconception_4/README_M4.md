# Misconception 4: "I'll build everything from scratch"

## Where You Are

You built a PI controller out of gain, integrator and sum blocks in module 1. It is correct. You can read every block in it and explain exactly what each one does. It has worked for three modules.

Now the robot drives onto a rug.

## The Takeaway

> Your project is from scratch. Each element does not have to be.

Spend your time on what is unique to your problem. Reuse components somebody else has already built, tested and documented.

## What Is In This Folder

| File | What it is for |
| --- | --- |
| `M4_HandBuiltPI.slx` | The loop with your module 1 PI controller. **Start here.** |
| `M4_PIDBlock.slx` | The solution. Open it after you have built your own fix. |
| `setup_M4_parameters.m` | Motor, driver limit, gains and the rug. |
| `run_M4_windup.m` | Runs one model and saves its plot. |
| `M4_HandBuiltPI.png` | The generated plot for the starting model. |
| `M4_PIDBlock.png` | The generated plot for the solution. |

Two things about this loop are worth knowing before you run it.

**There is no transport delay.** Module 3's 60 ms is gone. This module is about what is *inside* the controller, so everything outside it is kept quiet. The delay comes back in module 5.

**There is no Saturation block on the loop.** The `+/-12 V` ceiling lives inside the `DC Motor` subsystem, as `Driver Limit`. That is where it physically is: the battery and the H-bridge cannot deliver more, whatever the control law asks for. Open the motor and look at it before you start — the whole module turns on the difference between a limit the hardware imposes and a limit the controller knows about.

## How To Run It

```matlab
cd misconception_4
run_M4_windup
```

Or click the module 4 shortcut on the Project tab.

## Work Through It In This Order

### 1. The rug

At `t = 0.6 s` a load of `0.120 N.m` appears on the wheel and stays for 0.8 seconds. The motor can only just make `0.120 N.m` at 12 V, so the wheel stalls and briefly runs backwards. It cannot reach commanded speed no matter what the controller asks for.

That is an ordinary thing for a floor robot. Thick carpet, a cable, a transition strip.

### 2. Watch what your controller does about it

```matlab
run_M4_windup
```

```text
Commanded speed                          10.0 rad/s
Slowest speed on the rug                 -1.8 rad/s
Peak speed after the rug                 28.8 rad/s
Peak voltage requested                   26.5 V
Peak voltage the driver can give         12.0 V
Back inside the 2 % band                 1.53 s
```

Look at the **lower** panel first. While the wheel is stalled, your controller's requested voltage climbs in a straight line to **26.5 V**. The driver can give 12. It has been asking for more and more of something it was never going to get.

Then look at the **upper** panel. When the rug clears, the wheel takes off to **29 rad/s** — nearly three times what you asked for — and takes a second and a half to settle.

### 3. Understand why

The integral term accumulates error. While the wheel is stalled the error never goes away, so the integrator keeps climbing — even though the voltage reaching the motor has been pinned at 12 V the whole time and nothing the integrator adds can possibly get through.

When the rug clears, all of that accumulated demand is still sitting in the integrator. The only way it comes back down is for the error to go *negative*, which means the wheel has to overshoot and stay above the commanded speed until the integral has burned off.

This is **integrator windup**. It is not a bug in your maths. Your PI controller is a correct PI controller. It simply has no way of knowing that its output stopped being listened to.

### 4. Look for where you would fix it

Open `M4_HandBuiltPI/PI Controller`.

There is no place to put the fix. You would have to design a mechanism: detect that the output has saturated, decide what the integrator should do about it, wire that back in. Then test it. Then document it. Then explain it to whoever reviews your model.

Sit with that for a moment before the next step. The absence is the point.

### 5. Build the fix — by not building it

Replace the controller with one somebody has already built:

1. Open the Simulink Library Browser and find **Continuous > PID Controller**.
2. Drag it onto the canvas next to your `PI Controller` subsystem.
3. Delete the `PI Controller` subsystem and wire the new block in its place.
4. Double-click it and set:
   - **Controller** to `PI`
   - **Proportional (P)** to `0.65`, **Integral (I)** to `2.2`
   - Tick **Limit output**, with upper `12` and lower `-12`
   - **Anti-windup method** to `clamping`
5. Save and run it:

```matlab
run_M4_windup("M4_HandBuiltPI")
```

Everything that took you a module to build by hand, and the thing you could not build at all, is on one dialog.

### 6. Check your work

`M4_PIDBlock.slx` is the finished version. Run it:

```matlab
run_M4_windup("M4_PIDBlock")
```

```text
Peak speed after the rug                 14.6 rad/s
Peak voltage requested                   12.0 V
Back inside the 2 % band                 1.16 s
```

The requested voltage never exceeds what the driver can deliver, so there is nothing to unwind. Peak speed drops from 29 to 15 rad/s and recovery is a third faster.

It still overshoots more than the `10 %` in the requirements block — the requirement is written for a commanded step, and being shoved by a rug is a disturbance, not a command. Anti-windup fixed the windup. It did not tune your controller. Module 5 does that.

### 7. Now read the rest of that dialog

While it is open, look at what else is on it — every one of these is a question somebody already answered, tested and documented:

| Setting | The question it answers |
| --- | --- |
| Anti-windup method | What should the integrator do while the output is saturated? |
| Time domain | Continuous or discrete? *You will need discrete on a processor.* |
| Integrator method | Forward Euler, backward Euler, trapezoidal? |
| External reset | How do you clear the integrator when the controller is disabled? |
| Initial conditions | What does the integrator start at, and can that come from a signal? |
| Output limits | What can the actuator actually deliver? |
| Tracking mode | How do you hand control over without the output jumping? |
| Filter coefficient | How do you stop the derivative amplifying noise, if you add D? |

Two of those are worth a sentence each, because they bite on real robots:

**Integrator reset.** The robot pauses between cleaning passes. Your controller is disabled, but the integrator holds everything it accumulated while standing still — and dumps it the moment you re-enable.

**Tracking mode, or bumpless transfer.** The robot docks under manual control, then hands back to the speed loop. If the integrator does not know what the output was during manual control, the wheel jumps at the handover.

### 8. The point

You could build every one of those. None of them is beyond you.

But each one is a thing to design, test, document, review and maintain — and none of it is what makes your robot different from anybody else's. The controller is not your product. The robot is.

## Requirements

Unchanged, and on the canvas of every model:

```text
Step command        0 to 10 rad/s
Rise time           < 0.30 s
Settling time       < 0.80 s
Overshoot           < 10 %
Steady-state error  < 2 %
Motor voltage       within +/-12 V
```

## Where This Applies Beyond Simulink

The same judgement applies to a PID class in a Python library, a motor driver from a vendor, or a filter implementation from a standard. And it applies to code an AI agent writes for you: asking an agent to recreate a PID controller from scratch spends effort on a solved problem, can still get the edge cases wrong, and leaves you holding something nobody has validated. Reuse what is trusted. Spend your judgement on what is yours.

## Notes For Facilitators

Show the voltage panel before the speed panel. The ramp climbing past the 12 V line is the mechanism, and once the room sees it the overshoot is obvious rather than surprising.

Step 4 is the beat that matters. Give people a moment to actually look for where the fix would go inside the hand-built PI, and let the absence land before you reach for the library.

**Do step 5 live.** Dragging in the block, deleting the subsystem and ticking two boxes takes under a minute, and doing it in front of the room is far stronger than opening a finished model. `M4_PIDBlock.slx` is there so you have something to fall back on if the live edit goes wrong, and so self-paced learners can check themselves.

Do not read the dialog table aloud. Scroll the real dialog and let people see the length of it.
