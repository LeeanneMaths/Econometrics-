clear all;
close all;
clc;
% Adjusting beta to match an annual interest rate of 4%
target_annual_rate = 0.04;  % Target annual interest rate

% Define the equation for the beta calibration
function F = calibrate_beta(beta, target_annual_rate)
    % Use the Euler equation to relate beta to the annual interest rate
    r_annual = (1 / beta) - 1;  % Annual interest rate based on beta

    % Equation: Match the model's annual rate to the target
    F = r_annual - target_annual_rate;
end

% Initial guess for beta
beta_guess = 0.98;  % Starting value

% Use fsolve to solve for beta
options = optimoptions('fsolve', 'Display', 'iter');
[beta_solution, fval, exitflag] = fsolve(@(beta) calibrate_beta(beta, target_annual_rate), beta_guess, options);

% Output the calibrated beta
disp(['Calibrated beta to match a 4% annual interest rate: ', num2str(beta_solution)]);
