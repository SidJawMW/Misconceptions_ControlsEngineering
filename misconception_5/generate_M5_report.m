function reportFile = generate_M5_report()
%GENERATE_M5_REPORT Generate the controller validation report.
%
% The report answers four questions a design review actually asks, and
% nothing else:
%
%   1. What controller was designed?
%   2. What did it do when it was run?
%   3. Which artifacts is that evidence drawn from?
%   4. Does it meet the requirements?
%
% Everything in it is pulled from the model and the validation run rather
% than typed in, so it cannot quietly go stale. That is the whole argument:
% not that the report is pretty, but that regenerating it is cheap enough to
% do on every change.

moduleFolder = fileparts(mfilename("fullpath"));
results = run_M5_validation();

if exist("slreportgen.report.Report", "class") ~= 8
    reportFile = generateHtmlFallback(moduleFolder, results);
    fprintf("Simulink Report Generator was not detected. Generated HTML fallback:\n  %s\n", reportFile);
    return;
end

import mlreportgen.report.*
import mlreportgen.dom.*

loopModel = results.sourceModel;
controllerModel = results.controllerModel;
load_system(fullfile(moduleFolder, loopModel + ".slx"));
load_system(fullfile(moduleFolder, controllerModel + ".slx"));

rpt = slreportgen.report.Report(fullfile(moduleFolder, "M5_Toolchain_Report"), "html-file");
rpt.Locale = "en";

append(rpt, TitlePage( ...
    "Title", "Speed Controller Validation Report", ...
    "Subtitle", "Brushed DC wheel motor, differential-drive floor robot", ...
    "Author", "Controls Engineering Workshop", ...
    "PubDate", string(datetime("now"))));
append(rpt, TableOfContents());

% 1. What was designed --------------------------------------------------
controllerChapter = Chapter("Title", "Controller Summary");
append(controllerChapter, Paragraph(summaryText(results)));
append(controllerChapter, buildControllerTable(results));
append(rpt, controllerChapter);

% 2. What it did --------------------------------------------------------
metricsChapter = Chapter("Title", "Validation Metrics");
append(metricsChapter, buildMetricsTable(results));
if isfile(results.plotFile)
    plotImage = Image(results.plotFile);
    plotImage.Width = "6.5in";
    append(metricsChapter, plotImage);
end
append(rpt, metricsChapter);

% 3. Where the evidence comes from --------------------------------------
artifactChapter = Chapter("Title", "Model-Based Design Artifacts");
append(artifactChapter, Paragraph( ...
    "The metrics above were produced by simulating " + loopModel + ...
    ", which contains the plant, the measurement delay and the controller " + ...
    "being implemented. Code is generated from " + controllerModel + ...
    ", which contains the controller alone."));

loopSection = Section("Title", "Validation Loop: " + loopModel);
loopDiagram = slreportgen.report.Diagram(loopModel);
loopDiagram.Snapshot.ScaleToFit = true;
append(loopSection, loopDiagram);
append(artifactChapter, loopSection);

controllerSection = Section("Title", "Code Generation Boundary: " + controllerModel);
controllerDiagram = slreportgen.report.Diagram(controllerModel + "/Speed Controller");
controllerDiagram.Snapshot.ScaleToFit = true;
append(controllerSection, controllerDiagram);
append(artifactChapter, controllerSection);
append(rpt, artifactChapter);

% 4. Does it meet the requirement ---------------------------------------
complianceChapter = Chapter("Title", "Requirements Compliance");
append(complianceChapter, buildComplianceTable(results));
append(complianceChapter, Paragraph(verdictText(results)));
append(rpt, complianceChapter);

close(rpt);
reportFile = rpt.OutputPath;

fprintf("Generated validation report:\n  %s\n", reportFile);
end

% ------------------------------------------------------------------------
function text = summaryText(results)
params = results.parameters;
text = sprintf([ ...
    'A parallel-form PI controller regulates the speed of one wheel motor ' ...
    'to a commanded %g rad/s. It runs discrete at %g s, the rate of the ' ...
    'embedded speed task, and limits its own output to +/-%g V with ' ...
    'clamping anti-windup so that a stalled wheel cannot wind the ' ...
    'integrator up against a voltage the driver cannot deliver. The gains ' ...
    'were obtained with PID Tuner against a linearization of the loop, ' ...
    'then validated by simulation against the requirements below.'], ...
    params.speedCommand_radps, params.controllerSampleTime_s, ...
    params.actuatorLimit_V);
end

function text = verdictText(results)
[~, ~, passed] = complianceRows(results);
if all(passed)
    text = "All requirements are met. The controller is cleared for " + ...
        "code generation from the boundary shown above.";
else
    failedCount = sum(~passed);
    text = sprintf(['%d of %d requirements are not met. The controller ' ...
        'is not cleared for implementation.'], failedCount, numel(passed));
end
end

% ------------------------------------------------------------------------
function tableReporter = buildControllerTable(results)
import mlreportgen.report.*
import mlreportgen.dom.*
params = results.parameters;

body = { ...
    "Structure", "PI, parallel form"; ...
    "Proportional gain, Kp", sprintf("%.3f", results.gains.Kp); ...
    "Integral gain, Ki", sprintf("%.3f", results.gains.Ki); ...
    "Sample time", sprintf("%g s", params.controllerSampleTime_s); ...
    "Output limit", sprintf("+/-%g V", params.actuatorLimit_V); ...
    "Anti-windup", "Clamping"; ...
    "Measurement delay allowed for", sprintf("%g ms", params.softwareDelay_s * 1000)};

tableReporter = formalTable(["Property", "Value"], body, "Controller as designed");
end

function tableReporter = buildMetricsTable(results)
import mlreportgen.report.*
import mlreportgen.dom.*
metrics = results.metrics;

body = { ...
    "Rise time, 10-90 %", sprintf("%.3f s", metrics.riseTime_s); ...
    "Settling time, 2 % band", sprintf("%.3f s", metrics.settlingTime_s); ...
    "Overshoot", sprintf("%.2f %%", metrics.overshoot_pct); ...
    "Steady-state error", sprintf("%.2f %%", metrics.steadyStateError_pct); ...
    "Peak requested voltage", sprintf("%.2f V", metrics.maxRequestedVoltage_V)};

tableReporter = formalTable(["Metric", "Measured"], body, ...
    "Measured from " + results.sourceModel);
end

function tableReporter = buildComplianceTable(results)
import mlreportgen.report.*
import mlreportgen.dom.*

[labels, cells, passed] = complianceRows(results);
body = cell(numel(labels), 4);
for idx = 1:numel(labels)
    body{idx, 1} = labels(idx);
    body{idx, 2} = cells{idx, 1};
    body{idx, 3} = cells{idx, 2};
    if passed(idx)
        body{idx, 4} = "PASS";
    else
        body{idx, 4} = "FAIL";
    end
end

tableReporter = formalTable(["Requirement", "Required", "Achieved", "Result"], ...
    body, "Requirement compliance");
end

function [labels, cells, passed] = complianceRows(results)
%COMPLIANCEROWS One row per requirement, with the verdict computed here so
%the table and the written verdict cannot disagree.
metrics = results.metrics;
params = results.parameters;

labels = ["Rise time"; "Settling time"; "Overshoot"; ...
    "Steady-state error"; "Requested voltage"];

required = { ...
    sprintf("< %.2f s", params.requiredRiseTime_s); ...
    sprintf("< %.2f s", params.requiredSettlingTime_s); ...
    sprintf("< %.1f %%", params.requiredOvershoot_pct); ...
    sprintf("< %.1f %%", params.requiredSSE_pct); ...
    sprintf("within +/-%.1f V", params.actuatorLimit_V)};

achieved = { ...
    sprintf("%.3f s", metrics.riseTime_s); ...
    sprintf("%.3f s", metrics.settlingTime_s); ...
    sprintf("%.2f %%", metrics.overshoot_pct); ...
    sprintf("%.2f %%", metrics.steadyStateError_pct); ...
    sprintf("%.2f V", metrics.maxRequestedVoltage_V)};

cells = [required, achieved];

passed = [ ...
    metrics.riseTime_s < params.requiredRiseTime_s; ...
    metrics.settlingTime_s < params.requiredSettlingTime_s; ...
    metrics.overshoot_pct < params.requiredOvershoot_pct; ...
    metrics.steadyStateError_pct < params.requiredSSE_pct; ...
    metrics.maxRequestedVoltage_V <= params.actuatorLimit_V];
end

function tableReporter = formalTable(headers, body, titleText)
import mlreportgen.report.*
import mlreportgen.dom.*
table = FormalTable(cellstr(headers), body);
table.Width = "100%";
table.Border = "solid";
table.ColSep = "solid";
table.RowSep = "solid";
tableReporter = BaseTable(table);
tableReporter.Title = titleText;
end

% ------------------------------------------------------------------------
function reportFile = generateHtmlFallback(moduleFolder, results)
%GENERATEHTMLFALLBACK Same four sections, without Report Generator.
reportFile = fullfile(moduleFolder, "M5_Toolchain_Report.html");
fid = fopen(reportFile, "w");
cleanup = onCleanup(@() fclose(fid));

params = results.parameters;
[labels, cells, passed] = complianceRows(results);

fprintf(fid, "<!doctype html>\n<html lang=""en"">\n<head>\n");
fprintf(fid, "<meta charset=""utf-8"">\n");
fprintf(fid, "<title>Speed Controller Validation Report</title>\n");
fprintf(fid, "<style>body{font-family:Arial,sans-serif;margin:32px;line-height:1.45;max-width:900px}table{border-collapse:collapse;margin-bottom:24px}th,td{border:1px solid #777;padding:6px 10px;text-align:left}th{background:#f0f0f0}.fail{color:#b00;font-weight:bold}</style>\n");
fprintf(fid, "</head>\n<body>\n");
fprintf(fid, "<h1>Speed Controller Validation Report</h1>\n");
fprintf(fid, "<p>Brushed DC wheel motor, differential-drive floor robot. Generated %s.</p>\n", ...
    string(datetime("now")));

fprintf(fid, "<h2>Controller Summary</h2>\n<p>%s</p>\n", summaryText(results));
fprintf(fid, "<table>\n<tr><th>Property</th><th>Value</th></tr>\n");
fprintf(fid, "<tr><td>Structure</td><td>PI, parallel form</td></tr>\n");
fprintf(fid, "<tr><td>Proportional gain, Kp</td><td>%.3f</td></tr>\n", results.gains.Kp);
fprintf(fid, "<tr><td>Integral gain, Ki</td><td>%.3f</td></tr>\n", results.gains.Ki);
fprintf(fid, "<tr><td>Sample time</td><td>%g s</td></tr>\n", params.controllerSampleTime_s);
fprintf(fid, "<tr><td>Output limit</td><td>+/-%g V</td></tr>\n", params.actuatorLimit_V);
fprintf(fid, "<tr><td>Anti-windup</td><td>Clamping</td></tr>\n");
fprintf(fid, "</table>\n");

fprintf(fid, "<h2>Validation Metrics</h2>\n");
fprintf(fid, "<p>Measured from %s.</p>\n", results.sourceModel);
if isfile(results.plotFile)
    [~, plotName, plotExt] = fileparts(results.plotFile);
    fprintf(fid, "<img src=""%s%s"" alt=""Validation plot"" style=""max-width:900px;width:100%%;"">\n", ...
        plotName, plotExt);
end

fprintf(fid, "<h2>Model-Based Design Artifacts</h2>\n");
fprintf(fid, "<p>Validation loop: <code>%s</code>. Code generation boundary: <code>%s</code>.</p>\n", ...
    results.sourceModel, results.controllerModel);

fprintf(fid, "<h2>Requirements Compliance</h2>\n");
fprintf(fid, "<table>\n<tr><th>Requirement</th><th>Required</th><th>Achieved</th><th>Result</th></tr>\n");
for idx = 1:numel(labels)
    if passed(idx)
        verdict = "PASS";
        cssClass = "";
    else
        verdict = "FAIL";
        cssClass = " class=""fail""";
    end
    fprintf(fid, "<tr><td>%s</td><td>%s</td><td>%s</td><td%s>%s</td></tr>\n", ...
        labels(idx), cells{idx, 1}, cells{idx, 2}, cssClass, verdict);
end
fprintf(fid, "</table>\n");
fprintf(fid, "<p>%s</p>\n", verdictText(results));
fprintf(fid, "</body>\n</html>\n");
end
