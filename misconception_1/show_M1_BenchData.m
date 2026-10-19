function varargout = show_M1_BenchData()
%SHOW_M1_BENCHDATA Load the motor bench-test data and plot it.
%
%   The data in M1_PRBSBenchData.mat is an open-loop bench run on a single
%   wheel motor: a pseudo-random binary voltage command applied to the motor,
%   and the wheel speed recorded off the encoder.
%
%   This puts the recorded channels into the base workspace, ready for the
%   System Identification app:
%
%       M1_time_s       time vector [s]
%       M1_voltage_V    commanded motor voltage [V]
%       M1_speed_radps  measured wheel speed [rad/s]
%       M1_Ts_s         sample interval [s]
%       M1_sysid_data   the same record as an iddata object
%
%   Then:
%       systemIdentification
%
%   and import M1_sysid_data from the workspace.

moduleFolder = fileparts(mfilename("fullpath"));
dataFile = fullfile(moduleFolder, "M1_PRBSBenchData.mat");

if ~isfile(dataFile)
    error("show_M1_BenchData:MissingData", ...
        "Cannot find %s", dataFile);
end

benchData = load(dataFile);
fields = fieldnames(benchData);
for idx = 1:numel(fields)
    assignin("base", fields{idx}, benchData.(fields{idx}));
end

plotBenchData(benchData);

fprintf("Bench data loaded from:\n  %s\n", dataFile);
fprintf("Workspace variables: %s\n", strjoin(fields', ", "));
fprintf("Record length %.0f s at %.0f Hz.\n", ...
    benchData.M1_time_s(end), 1 / benchData.M1_Ts_s);

if nargout > 0
    varargout{1} = benchData;
end
end

function plotBenchData(benchData)
figure("Name", "M1 Bench Data", "Color", "w", "Position", [100, 100, 900, 520]);
layout = tiledlayout(2, 1, "TileSpacing", "compact", "Padding", "compact");
title(layout, "Motor Bench Test");

nexttile;
stairs(benchData.M1_time_s, benchData.M1_voltage_V, "LineWidth", 1.0);
grid on;
ylabel("Voltage command [V]");
title("Commanded motor voltage");

nexttile;
plot(benchData.M1_time_s, benchData.M1_speed_radps, "LineWidth", 1.2);
grid on;
xlabel("Time [s]");
ylabel("Motor speed [rad/s]");
title("Measured wheel speed");
end
