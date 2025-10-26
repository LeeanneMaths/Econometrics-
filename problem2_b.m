clear all; close all; clc;

% Target capital-output ratio
target_KY_ratio = 3;

% Initial guess for beta
beta0 = 0.95;  % Start with an initial guess for beta

% Solve for beta using fsolve
options = optimoptions('fsolve', 'Display', 'iter');
[beta_solution, fval, exitflag] = fsolve(@(beta) capital_output_ratio(beta, target_KY_ratio), beta0, options);

% Check if fsolve was successful
if exitflag > 0
    % Display the calibrated value of beta
    disp(['Calibrated beta (that achieves K/Y = 3): ', num2str(beta_solution)]);
else
    disp('fsolve did not converge. Calibration failed.');
end

% Now solve the steady-state system with the calibrated beta
main_steady_state(beta_solution);

%% Function to compute the difference between the actual and target K/Y ratio
function difference = capital_output_ratio(beta, target_KY_ratio)
    % Parameters given in the problem
    gamma = 0.3;
    sigma = 2;
    A = 1;
    alpha = 0.33;
    delta = 0.025;
    tau_c = 0.10;
    tau_i = 0.15;
    
    % Initial guess for [c, n, k, w, q]
    x0 = [1, 0.7, 0.7, 0.7, 1];  % Initial guesses for the steady state variables

    % Solve the steady-state system for this beta
    options = optimoptions('fsolve', 'Display', 'none');
    x = fsolve(@(x) steady_state_conditions(x, beta, gamma, sigma, A, alpha, delta, tau_c, tau_i), x0, options);
    
    % Extract the capital (k) and output (y) from the steady-state solution
    k = x(3);  % Capital
    n = x(2);  % Labor
    
    % Calculate output using the production function
    y = A * k^alpha * n^(1 - alpha);
    
    % Compute the actual K/Y ratio
    actual_KY_ratio = k / y;
    
    % Return the difference between the actual and target K/Y ratio
    difference = actual_KY_ratio - target_KY_ratio;
end

%% Function to solve the steady-state system given a value of beta
function main_steady_state(beta)
    % Parameters for the steady state
    gamma = 0.3;
    sigma = 2;
    A = 1;
    alpha = 0.33;
    delta = 0.025;
    tau_c = 0.10;
    tau_i = 0.15;
    
    % Initial guess for [c, n, k, w, q]
    x0 = [1, 0.7, 0.7, 0.7, 1];
    
    % Solve the system of nonlinear equations using fsolve
    options = optimoptions('fsolve', 'Display', 'iter');
    [x, fval] = fsolve(@(x) steady_state_conditions(x, beta, gamma, sigma, A, alpha, delta, tau_c, tau_i), x0, options);
    
    % Display the steady-state solution along with the final value of beta
    disp('Steady-state solution:');
    disp(['Calibrated beta (β): ', num2str(beta)]);
    disp(['Consumption (c): ', num2str(x(1))]);
    disp(['Labor (n): ', num2str(x(2))]);
    disp(['Capital (k): ', num2str(x(3))]);
    disp(['Wage (w): ', num2str(x(4))]);
    disp(['Rental rate (q): ', num2str(x(5))]);
end

%% Steady-state conditions function
function F = steady_state_conditions(x, beta, gamma, sigma, A, alpha, delta, tau_c, tau_i)
    % Variables to solve for
    c = x(1);  % Consumption
    n = x(2);  % Labor
    k = x(3);  % Capital
    w = x(4);  % Wage rate
    q = x(5);  % Rental rate
    
    % Production function
    y = A * k^alpha * n^(1 - alpha);
    
    % Investment in steady state (i = delta * k)
    i = delta * k;
    
    % Government spending G
    G = tau_c * c + tau_i * (q * k + w * n);
    
    % Labor condition (LC)
    LC = -(1 - gamma) * (1 - n)^(-sigma)/(1 - tau_i) + gamma * c^(-sigma) * w / (1 + tau_c);
    
    % Euler equation (EE)
    EE = 1 - beta * ((1 - tau_i) * q + 1 - delta);
    
    % Aggregate resource constraint (ARC)
    ARC = q * k + w * n - delta * k - c;
    
    % Resource constraint for wage (Wage condition)
    Wage = w - (1 - alpha) * A * k^alpha * n^(-alpha);
    
    % Resource constraint for interest rate (Interest condition)
    Interest = q - alpha * A * k^(alpha - 1) * n^(1 - alpha);
    
    % Return system of equations
    F = [LC; EE; ARC; Wage; Interest];
end
