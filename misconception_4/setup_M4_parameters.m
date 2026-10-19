function params = setup_M4_parameters()
%SETUP_M4_PARAMETERS Parameters for misconception 4 PID Tuner examples.

params = struct();

% Same direct-drive brushed DC motor used in previous modules.
params.R_ohm = 2.0;
params.L_H = 1.0e-3;
params.Kt_Nm_per_A = 0.020;
params.Ke_V_per_radps = 0.080;
params.J_kgm2 = 5.0e-4;
params.b_Nm_per_radps = 5.0e-4;

% Speed-loop target.
params.speedCommand_radps = 10.0;
params.stepTime_s = 0.1;
params.stopTime_s = 4.0;
params.maxStep_s = 1.0e-3;
params.actuatorLimit_V = 12.0;

% Starting point shown in the PID Tuner workflow model: the clean-simulation
% gains from earlier modules. They are intentionally too aggressive once the
% realistic feedback path is included.
params.starting.Kp = 0.65;
params.starting.Ki = 2.20;

% Candidate gains to document as the PID Tuner result for this workshop.
% They are validated against the same realistic feedback path introduced in
% module 3.
% Chosen for margin, not for speed. A gain sweep over the realistic loop
% showed this point clears every time-domain requirement by roughly 50 % of
% its limit, where the previous 0.22/0.60 candidate sat within 5 % of the
% rise-time limit and could fail outright if the tuner sliders were nudged
% toward robustness.
params.tuned.Kp = 0.35;
params.tuned.Ki = 0.80;


% The wheel-stall disturbance.
%
% The robot drives onto a thick rug. At 12 V the motor can make 0.120 N.m of
% torque, so this load stalls the wheel: it cannot reach commanded speed no
% matter what the controller asks for. That is the condition integrator
% windup needs - the output pinned at its limit while the error refuses to
% go away.
%
% The value is chosen with some care. Below about 0.107 N.m the controller
% never saturates and there is nothing to wind up. Much above 0.120 N.m the
% load overpowers the motor and drives the wheel backwards, which is not
% what a rug does to a robot and would raise a distracting question.
params.loadTorque_Nm = 0.120;
params.loadOnTime_s = 0.6;
params.loadOffTime_s = 1.4;

% Requirements.
params.requiredRiseTime_s = 0.30;
params.requiredSettlingTime_s = 0.80;
params.requiredOvershoot_pct = 10.0;
params.requiredSSE_pct = 2.0;
end
