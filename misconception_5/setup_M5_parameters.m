function params = setup_M5_parameters()
%SETUP_M5_PARAMETERS Parameters for misconception 5 toolchain examples.

params = struct();

% Same direct-drive brushed DC motor used throughout the workshop.
params.R_ohm = 2.0;
params.L_H = 1.0e-3;
params.Kt_Nm_per_A = 0.020;
params.Ke_V_per_radps = 0.080;
params.J_kgm2 = 5.0e-4;
params.b_Nm_per_radps = 5.0e-4;

% Scenario and timing.
params.speedCommand_radps = 10.0;
params.stepTime_s = 0.1;
params.stopTime_s = 2.0;
params.controllerSampleTime_s = 0.02;
params.maxStep_s = 1.0e-3;
params.actuatorLimit_V = 12.0;

% PI controller gains carried forward from the validated M4 tuning.
% The gains you arrive with, carried straight through from modules 1 to 4.
% The model ships with these in the PID Controller block, NOT with the tuned
% answer: the whole exercise is to open PID Tuner, find out these no longer
% hold up once the measurement delay is back in the loop, and fix them.
params.starting.Kp = 0.65;
params.starting.Ki = 2.20;

% Where tuning lands, near enough. Used for the controller that goes to code
% generation, and as a sanity check if you want to compare your own result.
% It is not loaded into the speed loop.
params.controller.Kp = 0.35;
params.controller.Ki = 0.80;

% The one physical reality this module shows.
%
% 60 ms is a realistic total for a wheel-speed measurement on a small robot:
% a 20 ms control task, filtering inside the encoder driver, and a hop across
% a bus. At the loop's 13.2 rad/s crossover it costs 45 degrees of the 86
% degrees of phase margin the ideal loop had, which is why one unremarkable
% number moves the response as much as it does.
params.softwareDelay_s = 0.060;

% Requirements.
params.requiredRiseTime_s = 0.30;
params.requiredSettlingTime_s = 0.80;
params.requiredOvershoot_pct = 10.0;
params.requiredSSE_pct = 2.0;
end
