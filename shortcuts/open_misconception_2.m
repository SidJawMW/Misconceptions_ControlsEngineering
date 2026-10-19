function open_misconception_2()
%OPEN_MISCONCEPTION_2 Set up module 2: Performance against actuator limits.
%
%   Loads the module parameters into the base workspace, switches to the
%   module folder and opens its models. Nothing is simulated - press play
%   when you are ready.

openModule(2, "setup_M2_parameters", ["M2_PerformanceVsRequirements"]);
end
