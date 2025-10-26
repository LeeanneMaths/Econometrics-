clear all;
close all;
clc;

% Parameters
beta = 0.96154;  % Calibrated beta from part (b)
sigma_val = 2;   % CRRA parameter
h1 = 1;          % Labor productivity in period 1
h2 = 1.5;        % Labor productivity in period 2
r = 0.04;        % Annual interest rate of 4%
w = 0.4076;      % Wage rate
Psi = 0.30;      % Replacement rate for pension benefits

% Pension benefits
P3 = Psi * (h1 * w + h2 * w);
P4 = Psi * (h1 * w + h2 * w);

% Solve for social security tax rate (tau_ss)
tau_ss = (P3 + P4) / (h1 * w + h2 * w);

% System of equations with PAYG program
% Update the budget constraints to include tau_ss and pension payments

% Step 1: Express consumption in terms of c1 using the Euler equations
c2 = @(c1) (beta * (1 + r))^(1/sigma_val) * c1;
c3 = @(c2) (beta * (1 + r))^(1/sigma_val) * c2;
c4 = @(c3) (beta * (1 + r))^(1/sigma_val) * c3;

% Step 2: Substitute into the updated lifetime budget constraint
budget_constraint_payg = @(c1) c1 + c2(c1)/(1 + r) + c3(c2(c1))/(1 + r)^2 + c4(c3(c2(c1)))/(1 + r)^3 ...
                               - ((1 - tau_ss) * h1 * w + (1 - tau_ss) * h2 * w / (1 + r) + P3 / (1 + r)^2 + P4 / (1 + r)^3);

% Use fsolve to solve for c1
c1_guess = 0.3;  % Initial guess for c1
options = optimoptions('fsolve', 'Display', 'iter');
[c1_solution, fval, exitflag] = fsolve(budget_constraint_payg, c1_guess, options);

% Step 3: Calculate consumption values using the Euler equations
c1 = c1_solution;
c2 = c2(c1);
c3 = c3(c2);
c4 = c4(c3);

% Step 4: Calculate savings in each period
s1 = (1 - tau_ss) * h1 * w - c1;
s2 = (1 + r) * s1 + (1 - tau_ss) * h2 * w - c2;
s3 = (1 + r) * s2 + P3 - c3;
s4 = (1 + r) * s3 + P4 - c4;

% Display the results
fprintf('Life-Cycle Consumption Profile with PAYG:\n');
fprintf('c1 = %.4f, c2 = %.4f, c3 = %.4f, c4 = %.4f\n', c1, c2, c3, c4);
fprintf('Life-Cycle Savings Profile with PAYG:\n');
fprintf('s1 = %.4f, s2 = %.4f, s3 = %.4f, s4 = %.4f\n', s1, s2, s3, s4);
fprintf('Social Security Tax Rate: tau_ss = %.4f\n', tau_ss);
