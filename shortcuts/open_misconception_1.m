function open_misconception_1()
%OPEN_MISCONCEPTION_1 Set up module 1: What comes before tuning.
%
%   Loads the module parameters into the base workspace, switches to the
%   module folder and opens its models. Nothing is simulated - press play
%   when you are ready.

openModule(1, "setup_M1_parameters", ["M1_Starter_PI_Only", "M1_FirstPrinciplesMotor", "M1_Solution_ComparePlants"]);
end
