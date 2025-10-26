clear all;
clc;

% Parameters (adjusting certain values for better results)
beta = 0.9065;    % Discount factor (calibrated from part b)
gamma = 0.3;      % Weight on consumption in utility
sigma_val = 2;    % CRRA parameter
alpha = 0.33;     % Capital share in production
delta = 0.025;    % Depreciation rate
A = 0.95;         % TFP after shock (adjusting to 0.95)
tau_c = 0.05;     % Reduced consumption tax for adjustment
tau_l = 0.10;     % Reduced labor tax

% Adjusted initial guesses (closer to pre-shock steady state)
initial_guess = [0.7; 0.05; 0.2];  % Higher guesses for capital, labor, and consumption

% Define the system of equations for steady state with TFP shock
function F = steady_state_eqns(x, beta, gamma, sigma_val, alpha, delta, A, tau_c, tau_l)
    k = x(1); % Capital
    n = x(2); % Labor
    c = x(3); % Consumption

    % Production function: Y = A * K^alpha * N^(1-alpha)
    y = A * k^alpha * n^(1-alpha);

    % Investment: i = y - c
    i = y - c;

    % Rental rate of capital: r = alpha * (Y/K) - delta
    r = alpha * (y/k) - delta;

    % Wage rate: w = (1 - alpha) * Y / N
    w = (1 - alpha) * (y/n);

    % Euler equation for consumption
    lhs = c^(-sigma_val);
    rhs = beta * (1 + r) * (c^(-sigma_val));

    % Labor supply: marginal utility of labor-leisure tradeoff
    mu_l = (1 - gamma) * ((1 - n)^(1 - sigma_val));
    mu_c = gamma * (c^(1 - sigma_val));

    % System of equations to solve for k, n, c
    F(1) = lhs - rhs;                             % Euler equation
    F(2) = mu_l - w * mu_c;                       % Labor supply condition
    F(3) = i - delta * k;                         % Investment condition (capital accumulation)
end

% Solve the steady-state system
options = optimoptions('fsolve', 'Display', 'iter', 'MaxIterations', 500);
[sol, fval, exitflag] = fsolve(@(x) steady_state_eqns(x, beta, gamma, sigma_val, alpha, delta, A, tau_c, tau_l), initial_guess, options);

% Extract the solutions
k = sol(1); % Capital
n = sol(2); % Labor
c = sol(3); % Consumption

% Compute additional steady-state variables
y = A * k^alpha * n^(1-alpha);   % Output
i = y - c;                       % Investment
w = (1 - alpha) * (y/n);         % Wage
r = alpha * (y/k) - delta;       % Rental rate of capital

% Display the results
fprintf('New Steady-State with TFP Shock (A = %.2f):\n', A);
fprintf('Capital (k) = %.4f\n', k);
fprintf('Labor (n) = %.4f\n', n);
fprintf('Consumption (c) = %.4f\n', c);
fprintf('Output (y) = %.4f\n', y);
fprintf('Investment (i) = %.4f\n', i);
fprintf('Wage (w) = %.4f\n', w);
fprintf('Rental Rate (r) = %.4f\n', r);
