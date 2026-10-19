function open_misconception_3()
%OPEN_MISCONCEPTION_3 Set up module 3: The feedback path is part of the loop.
%
%   Loads the module parameters into the base workspace, switches to the
%   module folder and opens its models. Nothing is simulated - press play
%   when you are ready.

openModule(3, "setup_M3_parameters", ["M3_SimulatedLoop", "M3_MeasuredLoop"]);
end
