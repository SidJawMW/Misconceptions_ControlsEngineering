function params = setup_M2_parameters()
%SETUP_M2_PARAMETERS Parameters for misconception 2 examples.

params = struct();

% Same direct-drive brushed DC motor used in module 1.
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

% Actuator-system capability.
params.actuatorLimit_V = 12.0;

% Balanced controller: meets the speed requirements without asking for more
% than the actuator system can provide.
params.balanced.Kp = 0.65;
params.balanced.Ki = 2.20;

% Aggressive controller. Against an ideal actuator this meets every
% requirement and looks superb: 0.015 s rise, 4.4 % overshoot. It also asks
% for 60 V from a 12 V battery, and once the actuator limit is in the loop
% the integrator winds up during saturation and overshoot reaches about
% 16.9 %, breaking the 10 % requirement.
params.aggressive.Kp = 6.00;
params.aggressive.Ki = 60.00;

% Slider travel, chosen to reach the aggressive set comfortably.
params.KpSliderRange = [0, 8];
params.KiSliderRange = [0, 80];

% Requirements.
params.requiredRiseTime_s = 0.30;
params.requiredSettlingTime_s = 0.80;
params.requiredOvershoot_pct = 10.0;
params.requiredSSE_pct = 2.0;
end
