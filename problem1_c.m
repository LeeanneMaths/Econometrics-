clear all; close all;
tic
disp('--------- New run ---------');

% Parameter values
beta    = 0.98;       % Time preference (use calibrated beta from Problem 1(b))
sigma   = 2;          % Risk aversion
A       = 1;          % Productivity
alpha   = 0.33;       % Capital share
delta   = 0.05;       % Depreciation rate (15 years)
h_1     = 1;          % Labor supply of agent 1
h_2     = 1.5;        % Labor supply of agent 2
Psi     = 0.30;       % Replacement rate for pension

% Initial guess for variables
N       = 2.5;        % Fixed labor supply
K       = 0.1;        % Initial capital guess
w       = 0.22;       % Wage guess
r       = 0.0095;     % Interest rate from problem 1 (b)
R       = 1 + r;      % Gross interest rate

% Define the system of equations for fsolve to solve
options = optimset('Display','off');

% Initial guess for c1, c2, c3, c4, tau_ss
X0 = [0.1, 0.1, 0.1, 0.1, 0.6];  % Initial guess

% Use fsolve to solve the system of equations
X = fsolve(@budget_constraint, X0, options);

% Assign the solved values
c_1 = X(1);
c_2 = X(2);
c_3 = X(3);
c_4 = X(4);
tau_ss = X(5);

% Compute pensions
P_3 = Psi * (h_1 * w + h_2 * w);
P_4 = Psi * (h_1 * w + h_2 * w);

% Calculate savings s1, s2, s3 based on the solved consumption
s_1 = (1 - tau_ss) * h_1 * w - c_1;
s_2 = (1 - tau_ss) * h_2 * w + R * s_1 - c_2;
s_3 = (1 + r) * s_2 + P_3 - c_3;

% Ensure c_4 satisfies the final period consumption equation
c_4_check = (1 + r) * s_3 + P_4;

% Output steady-state variables Y, H, etc.
Y = A * K^alpha * N^(1 - alpha);
H = N;

% Display results
disp('--------- Results ---------');
disp(['Y = ' num2str(Y)]);
disp(['K = ' num2str(K)]);
disp(['H = ' num2str(H)]);
disp(['R = ' num2str(R)]);
disp(['w = ' num2str(w)]);

disp('----------------------------');
disp(['c1 = ' num2str(c_1)]);
disp(['c2 = ' num2str(c_2)]);
disp(['c3 = ' num2str(c_3)]);
disp(['c4 (solved) = ' num2str(c_4)]);
disp(['c4 (checked) = ' num2str(c_4_check)]);
disp(['tau_ss = ' num2str(tau_ss)]);
disp(['s1 = ' num2str(s_1)]);
disp(['s2 = ' num2str(s_2)]);
disp(['s3 = ' num2str(s_3)]);
disp(['P3 = ' num2str(P_3)]);
disp(['P4 = ' num2str(P_4)]);

toc

% Define the budget constraint system of equations, with Euler equations included
function F = budget_constraint(X)
    % Extract variables from X
    c_1 = X(1);
    c_2 = X(2);
    c_3 = X(3);
    c_4 = X(4);
    tau_ss = X(5);
    
    % Parameters
    h_1 = 1;  % Labor supply agent 1
    h_2 = 1.5;  % Labor supply agent 2
    w = 0.22;  % Updated wage guess
    r = 0.0095;  % Interest rate from problem 1 (b)
    R = 1 + r;  % Gross interest rate
    Psi = 0.30;  % Pension replacement rate
    beta = 0.98;  % Time preference
    sigma = 2;  % Risk aversion

    % Compute pensions
    P_3 = Psi * (h_1 * w + h_2 * w);
    P_4 = Psi * (h_1 * w + h_2 * w);

    % Euler equations
    F(1) = c_1^(-sigma) - beta * (1 + r) * c_2^(-sigma);  % Between periods 1 and 2
    F(2) = c_2^(-sigma) - beta * (1 + r) * c_3^(-sigma);  % Between periods 2 and 3
    F(3) = c_3^(-sigma) - beta * (1 + r) * c_4^(-sigma);  % Between periods 3 and 4
    
    % Budget constraint (life-cycle)
    F(4) = c_1 + c_2/R + c_3/R^2 + c_4/R^3 - (1 - tau_ss) * h_1 * w - (1 - tau_ss) * h_2 * w / R - P_3/R^2 - P_4/R^3;
    
    % Social security balance condition
    F(5) = P_3 + P_4 - tau_ss * (h_1 * w + h_2 * w);
end
