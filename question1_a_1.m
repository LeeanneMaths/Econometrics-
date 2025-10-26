clear all;
close all;
clc;
%% Parameters
beta = 0.98;         % Discount factor
sigma_val = 2;       % CRRA parameter (renamed from sigma to sigma_val)
h1 = 1;              % Labor productivity in period 1
h2 = 1.5;            % Labor productivity in period 2
alpha = 0.33;        % Capital share
A = 1;               % Total factor productivity
delta = 0.05;        % Depreciation rate

% Initial guess for fsolve and Gauss-Seidel
r_guess = 0.04;      % Initial guess for the interest rate
w_guess = 1;         % Initial guess for the wage
c_guess = [0.5, 0.5, 0.5, 0.5];  % Initial guess for consumption

%% Using Fsolve
% Define the system of equations
function F = steady_state_eqns(vars, sigma_val, h1, h2, alpha, A, delta, beta)
    % Unpack the variables
    c1 = vars(1);
    c2 = vars(2);
    c3 = vars(3);
    c4 = vars(4);
    w = vars(5);
    r = vars(6);
    
    % Euler equations (for steady state, including beta)
    eq1 = c1^(-sigma_val) - beta * (1 + r) * c2^(-sigma_val);  % Between period 1 and 2
    eq2 = c2^(-sigma_val) - beta * (1 + r) * c3^(-sigma_val);  % Between period 2 and 3
    eq3 = c3^(-sigma_val) - beta * (1 + r) * c4^(-sigma_val);  % Between period 3 and 4
    
    % Lifetime budget constraint
    lhs = c1 + c2 / (1 + r) + c3 / (1 + r)^2 + c4 / (1 + r)^3;
    rhs = h1 * w + h2 * w / (1 + r);
    eq4 = lhs - rhs;
    
    % Firm's condition: wage and interest rate equations
    H = h1 + h2 / (1 + r);   % Total effective labor
    K = ((w / (1 - alpha)) / (A * alpha))^(1 / (alpha - 1));  % Capital stock
    r_eq = A * alpha * (K / H)^(alpha - 1) - delta - r;  % Rental rate equation
    w_eq = (1 - alpha) * A * (K / H)^alpha - w;          % Wage equation
    
    % Combine all equations
    F = [eq1; eq2; eq3; eq4; r_eq; w_eq];
end

% Initial guess for variables [c1, c2, c3, c4, w, r]
initial_guess = [c_guess, w_guess, r_guess];

% Call fsolve and pass sigma_val, h1, h2, alpha, A, delta, beta as additional parameters
options = optimoptions('fsolve', 'Display', 'iter', 'FunctionTolerance', 1e-8, 'StepTolerance', 1e-8);
[sol_fsolve, fval, exitflag] = fsolve(@(vars) steady_state_eqns(vars, sigma_val, h1, h2, alpha, A, delta, beta), initial_guess, options);

% Extract solutions
c1_fsolve = sol_fsolve(1);
c2_fsolve = sol_fsolve(2);
c3_fsolve = sol_fsolve(3);
c4_fsolve = sol_fsolve(4);
w_fsolve = sol_fsolve(5);
r_fsolve = sol_fsolve(6);

% Display the solution
fprintf('Fsolve Solution:\n');
fprintf('c1 = %.4f, c2 = %.4f, c3 = %.4f, c4 = %.4f\n', c1_fsolve, c2_fsolve, c3_fsolve, c4_fsolve);
fprintf('w = %.4f, r = %.4f\n', w_fsolve, r_fsolve);
