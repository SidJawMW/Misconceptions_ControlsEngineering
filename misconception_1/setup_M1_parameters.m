function params = setup_M1_parameters()
%SETUP_M1_PARAMETERS Parameters for misconception 1 motor-speed examples.
%
% The model is intentionally simple: a direct-drive brushed DC motor speed
% loop for one wheel of a differential-drive floor robot. The no-gearbox
% assumption keeps the first-principles model small enough for early-career
% learners to inspect block by block.

params = struct();

% Brushed DC motor parameters.
params.R_ohm = 2.0;             % Armature resistance [ohm]
params.L_H = 1.0e-3;            % Armature inductance [H]
params.Kt_Nm_per_A = 0.020;     % Torque constant [N*m/A]
params.Ke_V_per_radps = 0.080;  % Back-EMF constant [V/(rad/s)]
params.J_kgm2 = 5.0e-4;         % Rotor/wheel lumped inertia [kg*m^2]
params.b_Nm_per_radps = 5.0e-4; % Viscous friction [N*m/(rad/s)]

% Control-loop scenario and requirements.
params.speedCommand_radps = 10.0;      % Target wheel speed [rad/s]
params.requiredRiseTime_s = 0.30;      % 10-90% rise time target [s]
params.requiredSettlingTime_s = 0.80;  % 2% settling time target [s]
params.requiredOvershoot_pct = 10.0;   % Maximum percent overshoot [%]
params.requiredSSE_pct = 2.0;          % Steady-state error target [%]

% The motor driver cannot deliver more than this, whatever the control law
% asks for. No model in this module gets anywhere near it - the tuned loop
% peaks at about 6.5 V - but it is part of the requirement from the first
% slide onward, so it appears on every model's requirements block. Module 2
% is where you find out what happens when you ask for more.
params.actuatorLimit_V = 12.0;         % Motor driver voltage limit [V]

% The starter model ships with the loop closed and the gains at zero, so you
% tune it from scratch rather than nudging somebody else's answer. With both
% gains at zero the controller requests no voltage and the wheel does not
% turn: that flat line is the correct starting point, not a broken model.
params.starterKp = 0.0;
params.starterKi = 0.0;

% A modest baseline PI controller. The point of this module is not the final
% tuning, but this lets the solution model run and meet the simplified
% requirements for the nominal plant. It is also roughly where hand-tuning
% lands you, so it is a fair target to aim the starter model at.
params.Kp = 0.65;
params.Ki = 2.20;

% Simulation settings.
params.stopTime_s = 2.0;
params.maxStep_s = 1.0e-3;

% Synthetic bench-test settings for the System Identification app workflow.
% The bench samples faster than the control loop does. That buys bandwidth
% for identification, and costs speed resolution: the counting window is
% shorter, so each sample resolves a coarser speed step. It is a real
% trade-off in encoder-based speed measurement, and it is why the bench data
% looks noisier than anything the controller sees.
params.prbsSampleTime_s = 0.005;
params.prbsDuration_s = 40.0;
params.prbsSwitchInterval_s = 0.20;
% Excite near the operating point. The robot runs its wheels at about
% 10 rad/s, and 1.5 V drives roughly +/-11 rad/s. Identifying at three times
% the operating speed, as a 4 V command would, is poor practice: it weights
% the fit toward a regime the controller never visits.
params.prbsAmplitude_V = 1.5;
params.randomSeed = 7;

% Bench instrumentation, on the OUTPUT channel only.
%
% The input is the voltage command generated in software, so it is known
% exactly and carries no measurement noise. Corrupting it would make this an
% errors-in-variables problem, which tfest and friends are not built for:
% they assume y = G(q)u + H(q)e, with the noise at the output.
%
% The encoder is a modest quadrature part, which is what a cost-sensitive
% direct-drive wheel motor actually gets. Speed is derived by counting edges
% over one sample interval, so the speed resolution follows directly from the
% count and the sample rate:
%
%     resolution = 2*pi / (countsPerRev * sampleTime)
%
% Deriving it rather than hard-coding it keeps the number honest. A 0.05 rad/s
% resolution at this sample rate would imply a 25133 count/rev encoder, which
% is a precision industrial part and not something this robot would carry.
%
% The count is also bounded from below by the steady-state requirement: the
% quantizer leaves the true speed up to half an LSB off the command, so the
% loop needs more than 785 counts/rev to hold speed to 2 %.
params.encoderCountsPerRev = 1000;
params.benchSpeedResolution_radps = ...
    2 * pi / (params.encoderCountsPerRev * params.prbsSampleTime_s);

% Edge timing jitter and electrical pickup on the encoder channel, on top of
% the quantization above. Derived as a fraction of the speed step, the same
% way modules 3 to 5 do it, so the two stay consistent if the encoder or the
% sample rate is ever changed.
params.sensorNoiseStd_radps = 0.2 * params.benchSpeedResolution_radps;

% Example identified plant approximation used in the solution model. This is
% the transfer function implied by the nominal first-principles model.
params.identifiedNumerator = params.Kt_Nm_per_A;
params.identifiedDenominator = [ ...
    params.L_H * params.J_kgm2, ...
    params.L_H * params.b_Nm_per_radps + params.R_ohm * params.J_kgm2, ...
    params.R_ohm * params.b_Nm_per_radps + ...
        params.Kt_Nm_per_A * params.Ke_V_per_radps];

% The LTI System block in the solution model reads this. It is a stand-in for
% the model you identify yourself: once you have estimated a plant in the
% System Identification app, export it to the workspace and point the block
% at it instead, or simply overwrite this field.
%
%     params.identifiedPlant = tf2;      % or whatever the app called it
%
% tf comes from Control System Toolbox, which the LTI System block needs
% anyway. If it is missing, say so plainly rather than failing later inside
% the model with a message that does not mention the licence.
if exist("tf", "file") ~= 2 && exist("tf", "builtin") ~= 5
    error("setup_M1_parameters:NoControlSystemToolbox", ...
        ["Control System Toolbox is required for the LTI System block in " ...
         "M1_Solution_ComparePlants. Install it, or open " ...
         "M1_FirstPrinciplesMotor instead, which needs only Simulink."]);
end
params.identifiedPlant = tf(params.identifiedNumerator, params.identifiedDenominator);
end
