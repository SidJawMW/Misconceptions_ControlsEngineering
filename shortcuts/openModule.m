function openModule(moduleNumber, setupFunction, modelNames)
%OPENMODULE Shared setup used by every misconception shortcut.
%
%   Closes the other modules' models, switches to this module's folder,
%   evaluates its parameter script into the base workspace, and opens its
%   models. The working folder is left inside the module so the run_*
%   scripts are immediately callable.
%
%   Nothing is simulated. Press play when you are ready.
%
%   Every other workshop model is closed, INCLUDING any you have edited but
%   not saved. Those edits are discarded. That is deliberate: during a live
%   session you want one clean module on screen, not a pile of half-tuned
%   models from three exercises ago. The command window names anything that
%   was discarded, so you can see what went.
%
%   If you want to keep an experiment, save the model before moving on.

projectFolder = fileparts(fileparts(mfilename("fullpath")));
moduleFolder = fullfile(projectFolder, "misconception_" + moduleNumber);

if ~isfolder(moduleFolder)
    error("openModule:MissingFolder", "Cannot find %s", moduleFolder);
end

closeOtherModules(projectFolder, modelNames);

cd(moduleFolder);
params = feval(setupFunction);
assignin("base", "params", params);

for idx = 1:numel(modelNames)
    modelFile = fullfile(moduleFolder, modelNames(idx) + ".slx");
    if isfile(modelFile)
        open_system(modelFile);
    else
        warning("openModule:MissingModel", "Model not found: %s", modelFile);
    end
end

fprintf("Misconception %d ready.\n", moduleNumber);
fprintf("  Folder      %s\n", moduleFolder);
fprintf("  Parameters  in base workspace as 'params', from %s\n", setupFunction);
fprintf("  Models      %s\n", strjoin(modelNames, ", "));

readmeFile = "README_M" + moduleNumber + ".md";
if isfile(fullfile(moduleFolder, readmeFile))
    fprintf("  Start with  %s\n", readmeFile);
end
end

function closeOtherModules(projectFolder, keepModels)
%CLOSEOTHERMODULES Tidy away models belonging to the other misconceptions.
%
%   Without this, moving through the workshop leaves every model you have
%   ever opened sitting in the window list. Only workshop models are touched;
%   anything else you have open is left alone.
%
%   Unsaved changes are discarded rather than preserved. close_system with a
%   second argument of 0 means "close without saving", which is what stops a
%   dirty model putting up a save prompt in the middle of a live session.

workshopModels = strings(0);
for moduleNumber = 1:5
    folder = fullfile(projectFolder, "misconception_" + moduleNumber);
    if ~isfolder(folder)
        continue
    end
    found = dir(fullfile(folder, "*.slx"));
    for idx = 1:numel(found)
        [~, name] = fileparts(found(idx).name);
        workshopModels(end + 1) = string(name); %#ok<AGROW>
    end
end

toClose = setdiff(workshopModels, keepModels);
discarded = strings(0);

for idx = 1:numel(toClose)
    modelName = toClose(idx);
    if ~bdIsLoaded(modelName)
        continue
    end
    if strcmp(get_param(char(modelName), "Dirty"), "on")
        discarded(end + 1) = modelName; %#ok<AGROW>
    end
    close_system(modelName, 0);
end

if ~isempty(discarded)
    fprintf("  Discarded   unsaved changes in %s\n", strjoin(discarded, ", "));
end
end
