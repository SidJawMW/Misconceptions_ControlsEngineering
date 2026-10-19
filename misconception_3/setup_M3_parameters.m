function params = setup_M3_parameters()
%SETUP_M3_PARAMETERS Parameters for misconception 3 examples.

params = struct();

% Same direct-drive brushed DC motor used in modules 1 and 2.
params.R_ohm = 2.0;
params.L_H = 1.0e-3;
params.Kt_Nm_per_A = 0.020;
params.Ke_V_per_radps = 0.080;
params.J_kgm2 = 5.0e-4;
params.b_Nm_per_radps = 5.0e-4;

% Speed-loop target.
params.speedCommand_radps = 10.0;
params.stepTime_s = 0.1;
params.stopTime_s = 2.0;
params.maxStep_s = 1.0e-3;

% Actuator-system capability carried forward from module 2.
params.actuatorLimit_V = 12.0;

% PI gains carried forward from modules 1 and 2. They work well when the
% feedback is immediate. They are deliberately NOT retuned once the transport
% delay is in the loop: this module is about noticing the delay, not about
% tuning around it.
params.ideal.Kp = 0.65;
params.ideal.Ki = 2.20;

% The one physical reality this module shows.
%
% 60 ms is a realistic total for a wheel-speed measurement on a small robot:
% a 20 ms control task, filtering inside the encoder driver, and a hop across
% a bus. At the loop's 13.2 rad/s crossover it costs 45 degrees of the 86
% degrees of phase margin the ideal loop had, which is why one unremarkable
% number moves the response as much as it does.
params.softwareDelay_s = 0.060;

% Requirements from modules 1 and 2.
params.requiredRiseTime_s = 0.30;
params.requiredSettlingTime_s = 0.80;
params.requiredOvershoot_pct = 10.0;
params.requiredSSE_pct = 2.0;
end
