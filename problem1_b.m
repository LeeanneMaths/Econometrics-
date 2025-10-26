clear all; close all;
tic
disp('--------- New run ---------');

% Target interest rate: r_annual = 4%
r_annual = 0.04;
R_target = (1 + r_annual)^15;  % Convert annual rate to 15-year rate
disp(['Target R (15-year): ' num2str(R_target)]);  % Display target R for reference

% Parameter values (adjust beta bounds to match your classmate's result)
beta_lower = 0.93;  % Set lower bound for beta closer to your classmate's result
beta_upper = 0.95;  % Set upper bound slightly higher to allow precision
tolerance = 1e-6;  % Smaller tolerance for more precise search
max_iter = 1000;   % Increase max iterations

sigma   = 2;         % Risk aversion parameter
A       = 1;         % Productivity factor
alpha   = 0.33;      % Capital share
delta   = 0.5367;    % Depreciation rate (15 years)
h_1     = 1;         % Labor supply of agent 1
h_2     = 1.5;       % Labor supply of agent 2

% Set reasonable initial capital and wage
K       = 1;         % Initial guess for capital
Nold    = 2.5;       % Initial labor supply
w       = (1 - alpha) * A * K^alpha * Nold^(-alpha);    % Initial wage guess

iter = 0;
beta_diff = 100;  % Initialize difference
beta_guess = (beta_lower + beta_upper) / 2;

% Begin iterative search for beta using bisection method
while beta_diff > tolerance && iter < max_iter
    iter = iter + 1;
    
    % Household problem: Solving for consumption and savings
    R       = 1 + alpha * A * K^(alpha - 1) * Nold^(1 - alpha) - delta;  % Initial gross interest rate
    lambda_sig = (h_1 * w + h_2 * w / R) / ((1 + (1 / R) * (1 / (R * beta_guess))^(-1 / sigma) + ...
                    (1 / R^2) * (1 / (R^2 * beta_guess^2))^(-1 / sigma) + ...
                    (1 / R^3) * (1 / (R^3 * beta_guess^3))^(-1 / sigma)));
    
    c_1 = lambda_sig;
    c_2 = lambda_sig * (1 / (R * beta_guess))^(-1 / sigma);
    c_3 = lambda_sig * (1 / (R^2 * beta_guess^2))^(-1 / sigma);
    c_4 = lambda_sig * (1 / (R^3 * beta_guess^3))^(-1 / sigma);
    
    % Savings
    s_1 = h_1 * w - c_1;
    s_2 = h_2 * w + R * s_1 - c_2;
    s_3 = R * s_2 - c_3;

    % Labor and capital market clearing
    N = 2.5;  % Fixed labor supply
    Knew = s_1 + s_2 + s_3;  % Total capital from savings
    
    % Convex update for capital to stabilize iteration
    K = 0.6 * K + 0.4 * Knew;  % More aggressive convex update
    
    % Firm's problem: Factor prices from firm's FOCs
    w = (1 - alpha) * A * K^alpha * N^(-alpha);  % Wage equation
    q = alpha * A * K^(alpha - 1) * N^(1 - alpha);  % Marginal product of capital
    r = q - delta;  % Interest rate (net of depreciation)
    R = 1 + r;  % Gross interest rate
    
    % Compare the result with the target interest rate
    beta_diff = abs(R - R_target);
    
    % Adjust beta using bisection method
    if R > R_target
        beta_upper = beta_guess;
    else
        beta_lower = beta_guess;
    end
    beta_guess = (beta_lower + beta_upper) / 2;  % Update beta guess
end

% Display the calibrated beta
disp(['Calibrated beta: ' num2str(beta_guess)]);
disp(['R achieved = ' num2str(R)]);
disp('---------------------------------');

% Output consumption and savings values
disp(['c1   = ' num2str(real(c_1))]);
disp(['c2   = ' num2str(real(c_2))]);
disp(['c3   = ' num2str(real(c_3))]);
disp(['c4   = ' num2str(real(c_4))]);
disp(['s1   = ' num2str(real(s_1))]);
disp(['s2   = ' num2str(real(s_2))]);
disp(['s3   = ' num2str(real(s_3))]);
disp('-------------------------- ');

toc
