function open_misconception_4()
%OPEN_MISCONCEPTION_4 Set up module 4: Tuning with a proven tool.
%
%   Loads the module parameters into the base workspace, switches to the
%   module folder and opens its models. Nothing is simulated - press play
%   when you are ready.

openModule(4, "setup_M4_parameters", ["M4_HandBuiltPI", "M4_PIDBlock"]);
end
