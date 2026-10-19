function varargout = run_M3_comparison()
%RUN_M3_COMPARISON Compare the simulated loop with the measured one.
%
% Both runs use the SAME PI gains. The only difference is the transport delay
% in the feedback path, so any change in the response comes from that one
% number and nothing else.
%
% Signals are read from the logged data rather than from To Workspace blocks.
% The same signals are in the Simulation Data Inspector after each run, where
% you can overlay the two and step through them with cursors.

params = setup_M3_parameters();
moduleFolder = fileparts(mfilename("fullpath"));
simulatedModel = "M3_SimulatedLoop";
measuredModel = "M3_MeasuredLoop";

for modelName = [simulatedModel, measuredModel]
    if ~isfile(fullfile(moduleFolder, modelName + ".slx"))
        authoringFolder = fullfile(fileparts(moduleFolder), "authoring");
        addpath(authoringFolder);
        build_M3_models();
        rmpath(authoringFolder);
        break
    end
end

load_system(fullfile(moduleFolder, simulatedModel + ".slx"));
load_system(fullfile(moduleFolder, measuredModel + ".slx"));

% Each case is judged on the speed signal that case actually has.
%
% In the simulated loop the feedback is a wire, so the motor speed IS the
% measurement. In the measured loop it is not: the encoder signal arrives
% 60 ms after the wheel turns. Plotting the motor's true speed there would
% hide the delay completely - the motor starts moving the instant the step
% lands, because a delay in the FEEDBACK path makes the controller's
% information old, it does not hold the motor back. What arrives late is the
% measurement, and the measurement is all you have on real hardware.
simulated = runCase(simulatedModel, "Simulated", "Motor speed", params);
measured = runCase(measuredModel, "Measured", "Measured speed", params);

results = struct();
results.simulated = simulated;
results.measured = measured;
results.parameters = params;

plotFile = fullfile(moduleFolder, "M3_SimulatedVsMeasured.png");
plotComparison(results, plotFile);
results.plotFile = plotFile;

assignin("base", "M3_results", results);

fprintf("M3 comparison complete. Transport delay: %.0f ms.\n", ...
    params.softwareDelay_s * 1000);
fprintf("Saved comparison plot to:\n  %s\n", plotFile);
fprintf("\n%-12s %8s %8s %10s %8s %10s\n", ...
    "Case", "Rise", "Settle", "Overshoot", "SSE", "Max Req V");
printMetrics(results.simulated);
printMetrics(results.measured);

if nargout > 0
    varargout{1} = results;
end
end

function caseData = runCase(modelName, label, speedSignal, params)
simOut = sim(modelName);
caseData = struct();
caseData.label = label;
caseData.speedSignal = speedSignal;
caseData.time_s = logged(simOut, speedSignal).Time;
caseData.speed_radps = logged(simOut, speedSignal).Data;
caseData.requestedVoltage_V = logged(simOut, "Requested voltage").Data;
caseData.speedCommand_radps = params.speedCommand_radps * ...
    double(caseData.time_s >= params.stepTime_s);
caseData.metrics = calculateMetrics(caseData, params);
end

function values = logged(simOut, signalName)
%LOGGED Pull one named signal out of the logged dataset.
values = simOut.logsout.getElement(char(signalName)).Values;
end

function metrics = calculateMetrics(caseData, params)
time_s = caseData.time_s;
speed_radps = caseData.speed_radps;
command = params.speedCommand_radps;

idx10 = find(speed_radps >= 0.1 * command & time_s >= params.stepTime_s, 1, "first");
idx90 = find(speed_radps >= 0.9 * command & time_s >= params.stepTime_s, 1, "first");
if isempty(idx10) || isempty(idx90)
    riseTime_s = NaN;
else
    riseTime_s = time_s(idx90) - time_s(idx10);
end

outsideBand = find(abs(speed_radps - command) > 0.02 * command & ...
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
metrics.maxRequestedVoltage_V = max(abs(caseData.requestedVoltage_V));
end

function plotComparison(results, plotFile)
%PLOTCOMPARISON One plot, on purpose.
%
%   Wheel speed is the only trace this module needs. Everything else is in
%   the Data Inspector if a question calls for it.
figureHandle = figure("Name", "M3 Simulated vs Measured", "Color", "w", ...
    "Position", [100, 100, 900, 480]);

plot(results.simulated.time_s, results.simulated.speedCommand_radps, ...
    "k--", "LineWidth", 1.1);
hold on;
plot(results.simulated.time_s, results.simulated.speed_radps, "LineWidth", 1.4);
plot(results.measured.time_s, results.measured.speed_radps, "LineWidth", 1.4);
grid on;
xlabel("Time [s]");
ylabel("Wheel speed [rad/s]");
title("Same Controller, Simulated Versus Measured");
legend("Command", "Simulated", "Measured (encoder)", "Location", "southeast");

exportgraphics(figureHandle, plotFile, "Resolution", 150);
end

function printMetrics(caseData)
metrics = caseData.metrics;
fprintf("%-12s %8.3f %8.3f %10.2f %8.2f %10.2f\n", ...
    caseData.label, ...
    metrics.riseTime_s, ...
    metrics.settlingTime_s, ...
    metrics.overshoot_pct, ...
    metrics.steadyStateError_pct, ...
    metrics.maxRequestedVoltage_V);
end
