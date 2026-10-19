function varargout = run_M5_validation()
%RUN_M5_VALIDATION Reproduce the closed-loop evidence for the module 5 report.
%
% This module has no loop model of its own. The controller was validated in
% module 4, against the plant and the realistic feedback path, so that is the
% model this script simulates. Keeping one validated loop rather than two
% copies is the same argument module 5 makes about toolchains: evidence is
% only worth something if there is exactly one source of it.
%
% Produces M5_ToolchainValidation.png and leaves M5_results in the base
% workspace for generate_M5_report.

params = setup_M5_parameters();
moduleFolder = fileparts(mfilename("fullpath"));
validatedModel = "M5_SpeedLoop";
sourceModel = fullfile(moduleFolder, validatedModel + ".slx");

if ~isfile(sourceModel)
    authoringFolder = fullfile(fileparts(moduleFolder), "authoring");
    addpath(authoringFolder);
    build_M5_models();
    rmpath(authoringFolder);
end

load_system(sourceModel);

% Validate the gains that are IN the model, whatever they are.
%
% This script used to overwrite them with the shipped values before
% simulating. That meant you could tune in PID Tuner, run this, and get back
% a different response with no explanation for the difference - because the
% script had quietly substituted its own answer. It no longer does. If these
% numbers disagree with what PID Tuner showed you, that is a real difference
% and worth chasing.
gains = struct();
gains.Kp = str2double(get_param(validatedModel + "/PID Controller", "P"));
gains.Ki = str2double(get_param(validatedModel + "/PID Controller", "I"));

simOut = sim(validatedModel);

trueSpeed = logged(simOut, "Motor speed");
measuredSpeed = logged(simOut, "Measured speed");
requestedVoltage = logged(simOut, "Requested voltage");
appliedVoltage = logged(simOut, "Applied voltage");

results = struct();
results.sourceModel = validatedModel;
results.controllerModel = "M5_SpeedController";
results.time_s = trueSpeed.Time;
results.speedCommand_radps = params.speedCommand_radps * ...
    double(trueSpeed.Time >= params.stepTime_s);
results.trueSpeed_radps = trueSpeed.Data;
results.measuredSpeed_radps = measuredSpeed.Data;
results.requestedVoltage_V = requestedVoltage.Data;
results.appliedVoltage_V = appliedVoltage.Data;
results.parameters = params;
results.gains = gains;
results.metrics = calculateMetrics(results, params);

plotFile = fullfile(moduleFolder, "M5_ToolchainValidation.png");
plotValidation(results, params, plotFile);
results.plotFile = plotFile;

assignin("base", "M5_results", results);

fprintf("M5 validation complete, using %s.\n", validatedModel);
fprintf("Gains read from the model:  Kp = %.3f   Ki = %.3f\n", gains.Kp, gains.Ki);
fprintf("Saved validation plot to:\n  %s\n", plotFile);
printRequirementCheck(results, params);

if nargout > 0
    varargout{1} = results;
end
end

function values = logged(simOut, signalName)
%LOGGED Pull one named signal out of the logged dataset.
values = simOut.logsout.getElement(char(signalName)).Values;
end

function metrics = calculateMetrics(results, params)
time_s = results.time_s;
speed_radps = results.trueSpeed_radps;
command = params.speedCommand_radps;

idx10 = find(speed_radps >= 0.1 * command & time_s >= params.stepTime_s, 1, "first");
idx90 = find(speed_radps >= 0.9 * command & time_s >= params.stepTime_s, 1, "first");
if isempty(idx10) || isempty(idx90)
    riseTime_s = NaN;
else
    riseTime_s = time_s(idx90) - time_s(idx10);
end

settlingBand = 0.02 * command;
outsideBand = find(abs(speed_radps - command) > settlingBand & ...
    time_s >= params.stepTime_s);
if isempty(outsideBand)
    settlingTime_s = 0;
elseif outsideBand(end) == numel(time_s)
    settlingTime_s = NaN;
else
    settlingTime_s = time_s(outsideBand(end) + 1) - params.stepTime_s;
end

metrics = struct();
metrics.riseTime_s = riseTime_s;
metrics.settlingTime_s = settlingTime_s;
metrics.overshoot_pct = max(0, (max(speed_radps) - command) / command * 100);
metrics.steadyStateError_pct = abs(command - speed_radps(end)) / command * 100;
metrics.maxRequestedVoltage_V = max(abs(results.requestedVoltage_V));
metrics.maxAppliedVoltage_V = max(abs(results.appliedVoltage_V));
end

function printRequirementCheck(results, params)
%PRINTREQUIREMENTCHECK State plainly whether every requirement is met.
metrics = results.metrics;
checks = { ...
    "Rise time",          metrics.riseTime_s,            params.requiredRiseTime_s,     "s"; ...
    "Settling time",      metrics.settlingTime_s,        params.requiredSettlingTime_s, "s"; ...
    "Overshoot",          metrics.overshoot_pct,         params.requiredOvershoot_pct,  "%"; ...
    "Steady-state error", metrics.steadyStateError_pct,  params.requiredSSE_pct,        "%"; ...
    "Requested voltage",  metrics.maxRequestedVoltage_V, params.actuatorLimit_V,        "V"};

fprintf("\nRequirement check\n");
fprintf("%-20s %10s %10s %9s %8s\n", "Requirement", "Achieved", "Limit", "Margin", "Result");
allPassed = true;
for idx = 1:size(checks, 1)
    achieved = checks{idx, 2};
    limit = checks{idx, 3};
    passed = achieved <= limit;
    allPassed = allPassed && passed;
    if passed
        result = "PASS";
    else
        result = "FAIL";
    end
    fprintf("%-20s %9.3f%-1s %9.3f%-1s %8.0f%% %8s\n", ...
        checks{idx, 1}, achieved, checks{idx, 4}, limit, checks{idx, 4}, ...
        100 * (1 - achieved / limit), result);
end

if allPassed
    fprintf("\nAll time-domain requirements met.\n");
else
    fprintf(2, "\nAt least one requirement is NOT met.\n");
end
end

function plotValidation(results, params, plotFile)
figureHandle = figure("Name", "M5 Validation", "Color", "w");
layout = tiledlayout(2, 1, "TileSpacing", "compact", "Padding", "compact");
title(layout, "Closed-Loop Evidence For The Implemented Controller");

nexttile;
plot(results.time_s, results.speedCommand_radps, "k--", "LineWidth", 1.1);
hold on;
plot(results.time_s, results.trueSpeed_radps, "LineWidth", 1.3);
plot(results.time_s, results.measuredSpeed_radps, "LineWidth", 1.1);
grid on;
ylabel("Speed [rad/s]");
title("Motor speed");
legend("Command", "True speed", "Measured speed", "Location", "southeast");

nexttile;
plot(results.time_s, results.requestedVoltage_V, "LineWidth", 1.3);
hold on;
plot(results.time_s, results.appliedVoltage_V, "LineWidth", 1.1);
yline(params.actuatorLimit_V, "k--", "+12 V limit", ...
    "LabelHorizontalAlignment", "left");
yline(-params.actuatorLimit_V, "k--", "-12 V limit", ...
    "LabelHorizontalAlignment", "left");
grid on;
xlabel("Time [s]");
ylabel("Voltage [V]");
title("Motor voltage");
legend("Requested voltage", "Applied voltage", "Location", "northeast");

exportgraphics(figureHandle, plotFile, "Resolution", 150);
end
