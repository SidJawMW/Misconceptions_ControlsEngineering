
function varargout = run_M4_windup(modelName)
%RUN_M4_WINDUP Run the speed loop over a rug and plot what the wheel does.
%
%   run_M4_windup                    runs M4_HandBuiltPI, the default
%   run_M4_windup("M4_PIDBlock")     runs the solution model instead
%
% The default is the hand-built PI you assembled in module 1: a gain, an
% integrator and a sum. It is correct control theory and it is missing
% something, and this script is how you find out what.
%
% Partway through the run the robot drives onto a rug. The load torque is
% more than the motor can push through on 12 V, so the wheel slows, the
% error refuses to go away, and the integrator keeps accumulating against a
% voltage command that is already pinned at the driver's limit. Watch the
% second panel: the controller asks for a voltage no battery on this robot
% can deliver, and keeps asking.
%
% Then the rug ends - and all of that accumulated integral has to be unwound
% before the controller will ease off.
%
% There is deliberately no second trace here. Fix it yourself first: replace
% the PI Controller subsystem with a PID Controller block from the Simulink
% library, set it to PI, enter the same gains, tick "Limit output" with
% +/-12 V, and choose an anti-windup method. Then run this script again
% against your model and see what changed.

if nargin < 1 || strlength(string(modelName)) == 0
    modelName = "M4_HandBuiltPI";
end
modelName = string(modelName);

params = setup_M4_parameters();
moduleFolder = fileparts(mfilename("fullpath"));

if ~isfile(fullfile(moduleFolder, modelName + ".slx"))
    authoringFolder = fullfile(fileparts(moduleFolder), "authoring");
    addpath(authoringFolder);
    build_M4_models();
    rmpath(authoringFolder);
end

load_system(fullfile(moduleFolder, modelName + ".slx"));

results = runCase(modelName, params);
results.parameters = params;

plotFile = fullfile(moduleFolder, "M4_" + modelName.extractAfter("M4_") + ".png");
plotRun(results, params, plotFile);
results.plotFile = plotFile;

assignin("base", "M4_results", results);

fprintf("Model: %s\n", modelName);
fprintf("Wheel stalled by %.2f N.m from %.1f s to %.1f s.\n", ...
    params.loadTorque_Nm, params.loadOnTime_s, params.loadOffTime_s);
fprintf("Saved plot to:\n  %s\n\n", plotFile);

metrics = results.metrics;
fprintf("%-34s %10.1f rad/s\n", "Commanded speed", params.speedCommand_radps);
fprintf("%-34s %10.1f rad/s\n", "Slowest speed on the rug", metrics.minSpeed_radps);
fprintf("%-34s %10.1f rad/s\n", "Peak speed after the rug", metrics.peakSpeed_radps);
fprintf("%-34s %10.1f V\n", "Peak voltage requested", metrics.peakRequest_V);
fprintf("%-34s %10.1f V\n", "Peak voltage the driver can give", params.actuatorLimit_V);
if isnan(metrics.recovery_s)
    fprintf("%-34s %10s\n", "Back inside the 2 % band", "never");
else
    fprintf("%-34s %10.2f s\n", "Back inside the 2 % band", metrics.recovery_s);
end

overshoot_pct = 100 * (metrics.peakSpeed_radps - params.speedCommand_radps) / ...
    params.speedCommand_radps;
fprintf("\nOvershoot after the disturbance clears: %.1f %% (limit %g %%)\n", ...
    overshoot_pct, params.requiredOvershoot_pct);

if nargout > 0
    varargout{1} = results;
end
end

function caseData = runCase(modelName, params)
simOut = sim(modelName);
speed = simOut.logsout.getElement("Motor speed").Values;
voltage = simOut.logsout.getElement("Requested voltage").Values;
caseData = struct();
caseData.modelName = modelName;
caseData.time_s = speed.Time;
caseData.speed_radps = speed.Data;
caseData.requestedVoltage_V = voltage.Data;
caseData.metrics = calculateMetrics(caseData, params);
end

function metrics = calculateMetrics(caseData, params)
time_s = caseData.time_s;
speed_radps = caseData.speed_radps;
command = params.speedCommand_radps;
onRug = time_s >= params.loadOnTime_s & time_s <= params.loadOffTime_s;
afterLoad = time_s > params.loadOffTime_s;

metrics = struct();
metrics.minSpeed_radps = min(speed_radps(onRug));
metrics.peakSpeed_radps = max(speed_radps(afterLoad));

outsideBand = find(abs(speed_radps - command) > 0.02 * command & afterLoad);
if isempty(outsideBand)
    metrics.recovery_s = 0;
elseif outsideBand(end) == numel(time_s)
    metrics.recovery_s = NaN;
else
    metrics.recovery_s = time_s(outsideBand(end) + 1) - params.loadOffTime_s;
end

metrics.peakRequest_V = max(abs(caseData.requestedVoltage_V));
end

function plotRun(results, params, plotFile)
figureHandle = figure("Name", "M4 " + results.modelName, "Color", "w", ...
    "Position", [100, 100, 900, 620]);
layout = tiledlayout(2, 1, "TileSpacing", "compact", "Padding", "compact");
switch results.modelName
    case "M4_HandBuiltPI", controllerLabel = "Hand-Built PI Controller";
    case "M4_PIDBlock",    controllerLabel = "PID Controller Block";
    otherwise,             controllerLabel = strrep(results.modelName, "_", " ");
end
title(layout, "Speed Loop Response to a Load Disturbance: " + controllerLabel, ...
    "FontWeight", "bold");

% Legend entries are built from explicit handles. Relying on plot order is
% fragile once a shaded patch and a yline are in the axes too.
nexttile;
hold on;
speedLine = plot(results.time_s, results.speed_radps, "LineWidth", 1.4);
commandLine = yline(params.speedCommand_radps, "k--", "LineWidth", 1.1);
shadeLoad(params);
grid on;
ylabel("Motor speed [rad/s]");
title("Motor Speed");
legend([commandLine, speedLine], "Command", "Measured", ...
    "Location", "northeast");

nexttile;
hold on;
voltageLine = plot(results.time_s, results.requestedVoltage_V, "LineWidth", 1.4);
limitLine = yline(params.actuatorLimit_V, "k--", "LineWidth", 1.1);
yline(-params.actuatorLimit_V, "k--", "LineWidth", 1.1, "HandleVisibility", "off");
shadeLoad(params);
grid on;
xlabel("Time [s]");
ylabel("Requested voltage [V]");
title("Requested Motor Voltage");
legend([limitLine, voltageLine], ...
    sprintf("+/-%g V driver limit", params.actuatorLimit_V), "Requested", ...
    "Location", "northeast");

exportgraphics(figureHandle, plotFile, "Resolution", 150);
end

function shadeLoad(params)
%SHADELOAD Mark the window where the wheel is on the rug.
%
%   Drawn after the lines so the y-limits are known, then pushed to the back
%   with uistack. Reordering the axes children by hand also works but
%   scrambles which legend entry belongs to which line.
limits = ylim;
patchHandle = patch( ...
    [params.loadOnTime_s, params.loadOffTime_s, params.loadOffTime_s, params.loadOnTime_s], ...
    [limits(1), limits(1), limits(2), limits(2)], ...
    [0.9, 0.9, 0.9], "EdgeColor", "none", "FaceAlpha", 0.6, "HandleVisibility", "off");
uistack(patchHandle, "bottom");
ylim(limits);
end
