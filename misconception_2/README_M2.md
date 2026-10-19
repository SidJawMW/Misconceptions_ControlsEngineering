# Misconception 2: "I need to maximize control performance"

## Where You Are

You finished module 1 with a plant you trust and a PI controller you tuned yourself on the sliders, sitting at `Kp = 0.65`, `Ki = 2.20`. It meets every requirement.

It is also, you suspect, a little sluggish. And you already know exactly which two sliders would fix that.

## The Takeaway

> Faster is not free. Exceeding your requirement quietly writes a stricter requirement for somebody else.

This module is about what happens at the **design stage**, before anyone has built anything. The physical consequences of pushing hardware past its limits belong to module 3.

## What Is In This Folder

| File | What it is for |
| --- | --- |
| `M2_PerformanceVsRequirements.slx` | The module 1 speed loop with `Kp`/`Ki` sliders. |
| `setup_M2_parameters.m` | Motor parameters, reference gain sets, and the requirements. |

## How To Run It

```matlab
cd misconception_2
open_system("M2_PerformanceVsRequirements")
```

Or click the module 2 shortcut on the Project tab.

**Open the Simulation Data Inspector** before you start. There are no Scope blocks in this workshop — logged signals go to the Data Inspector, which keeps every run so you can compare the tunings directly instead of remembering what the last one looked like.

## Work Through It In This Order

### 1. Run it as it stands

Your module 1 gains, your module 1 response:

```text
rise 0.148 s    settling 0.449 s    overshoot 2.1 %
```

Every requirement met. Note the **requested voltage** while you are here — it peaks around 6.5 V.

### 2. Push the gains up

Drag `Kp` toward `6` and `Ki` toward `60`, running as you go.

The response gets dramatically better:

```text
rise 0.015 s    settling 0.130 s    overshoot 4.4 %
```

A ten-times faster rise, better settling, overshoot still comfortably inside the limit. **Check it against the requirements. It passes all of them.** This is not a trick — against this plant, that tuning is genuinely excellent, and you would be right to prefer it.

### 3. Now look at the voltage

The requested voltage peaks around **60 V**.

Your robot has a 12 V battery.

### 4. Understand what you just did

You did not break anything. You did not violate a requirement. What you did was turn a controls decision into somebody else's problem:

- **Electrical** now need a 60 V bus. That is a different battery chemistry, a different pack, a different charger, and a different safety case.
- **Mechanical** now need to fit and cool it.
- **Procurement** now need a motor driver rated for it.
- **Test** now need to qualify all of that.

And none of them were in the room when you dragged the slider.

That is the real cost of "maximize performance". Not that it is impossible — it is entirely possible, and here is a controller that does it. The cost is that **exceeding your requirement levies a stricter requirement on everybody downstream**, and you are the only person who knows you did it.

### 5. Decide deliberately

There is more than one defensible answer:

- **Keep the balanced tuning.** It meets the requirement. A floor robot does not need a 15 ms wheel response.
- **Go and ask.** If the product genuinely needs it, make the case to the people who will pay for it, with the number in hand.
- **Find out what the bus can actually give you**, and tune to that, before you design against a number you invented.

The one answer that is not automatically right is "increase the gains and move on".

## Requirements

Unchanged from module 1:

```text
Step command        0 to 10 rad/s
Rise time           < 0.30 s
Settling time       < 0.80 s
Overshoot           < 10 %
Steady-state error  < 2 %
```

Note what is **not** on that list: any constraint on the voltage. That is exactly why this is easy to miss. Nothing in your requirement set stops you asking for 60 V, and the simulation will happily give it to you.

## Reference Gain Sets

```text
Balanced     Kp = 0.65    Ki = 2.20     about 6.5 V
Aggressive   Kp = 6.00    Ki = 60.00    about 60 V
```

The aggressive figures are a landmark, not a recommendation — they tell you roughly how far to push before the point lands.

## What You Should Take Away

A simulation will confirm whatever you leave out of it. There is no battery in this model, so there is no limit on what the controller can ask for, and the response you get back looks like a success.

The question is not "how fast can I make it?" It is "what response does this robot need, and what am I asking other people to build so I can have it?"

## Notes For Facilitators

Do not mention voltage during step 2. Let the room see a ten-times-faster response that passes every requirement and let them commit to it. Then show the number.

The reaction you want is not "oops, that is too fast" — it is "wait, who is paying for that?" If someone gets there on their own, let them say it.

Keep this section short. Brian's note from the September check-in was explicit: the physical consequences of hitting a limit are module 3's job, and the audience already knows a battery has a voltage. The value here is purely the requirements argument.
