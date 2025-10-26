clear all;
clc;

% Parameters (same as in part (a), but now we adjust beta)
gamma = 0.3;
sigma_val = 2;
alpha = 0.33;
delta = 0.025;
A = 1;  % Total factor productivity
tau_c = 0.1;  % Consumption tax rate
tau_l = 0.15; % Labor income tax rate
beta_guess = 0.99; % Initial guess for beta

% Define the equation for K/Y = 3
function F = calibrate_beta(beta, gamma, sigma_val, alpha, delta, A, tau_c, tau_l)
    % Given beta, solve the steady state values
    % (Use the same steady-state calculation as in part a)
    
    % Solve for the steady state values using the given beta
    % Labor-leisure condition
    n = (1 - gamma) * ((1 - tau_l) * A * alpha)^(1/(1 - alpha + gamma));  % labor

    % Output
    y = A * n^(1 - alpha);

    % Wage
    w = (1 - alpha) * A * n^(-alpha);

    % Rental rate
    r = alpha * A * n^(1 - alpha) - delta;

    % Capital accumulation equation: k = beta*(1 + r)
    k = beta * (1 + r);

    % Consumption
    c = (1 - tau_c) * y - delta * k;

    % Calculate K/Y ratio
    k_to_y_ratio = k / y;
    
    % Objective: want K/Y = 3
    F = k_to_y_ratio - 3;
end

% Use fsolve to solve for beta
options = optimoptions('fsolve', 'Display', 'iter');
[beta_solution, fval, exitflag] = fsolve(@(beta) calibrate_beta(beta, gamma, sigma_val, alpha, delta, A, tau_c, tau_l), beta_guess, options);

% Display the calibrated beta
fprintf('Calibrated beta to match K/Y = 3: %.4f\n', beta_solution);
