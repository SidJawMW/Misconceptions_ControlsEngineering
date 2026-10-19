function open_misconception_5()
%OPEN_MISCONCEPTION_5 Set up module 5: The toolchain and the implementation boundary.
%
%   Loads the module parameters into the base workspace, switches to the
%   module folder and opens its models. Nothing is simulated - press play
%   when you are ready.

openModule(5, "setup_M5_parameters", ["M5_SpeedLoop", "M5_SpeedController"]);
end
