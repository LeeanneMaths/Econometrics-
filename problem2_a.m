clear all; close all; clc;
main_steady_state();
function main_steady_state()
% Parameters given in the problem
beta = 0.99;
gamma = 0.3;
sigma = 2;
A = 1;
alpha = 0.33;
delta = 0.025;
tau_c = 0.10;
tau_i = 0.15;
% Initial guess for [c, n, k, w, q]
x0 = [1, 0.7, 0.7, 0.7, 1];
% Solve system of nonlinear equations using fsolve
options = optimoptions('fsolve', 'Display', 'iter');
[x, fval] = fsolve(@(x) steady_state_conditions(x, beta, gamma, sigma, A, alpha, delta, tau_c, tau_i), x0, options);
% Display the solution
disp('Steady-state solution:');
disp(['Consumption (c): ', num2str(x(1))]);
disp(['Labor (n): ', num2str(x(2))]);
disp(['Capital (k): ', num2str(x(3))]);
disp(['Wage (w): ', num2str(x(4))]);
disp(['Rental rate (q): ', num2str(x(5))]);
end
function F = steady_state_conditions(x, beta, gamma, sigma, A, alpha, delta, tau_c, tau_i)
% Variables to solve for
c = x(1); % Consumption
n = x(2); % Labor
k = x(3); % Capital
w = x(4); % Wage rate
q = x(5); % Rental rate
% Production function
y = A * k^alpha * n^(1 - alpha);
% Investment in steady-state (i = delta * k)
i = delta * k;
% Government spending G
G = tau_c * c + tau_i * (q * k + w * n);
% Labor Condition (LC)
LC = -(1 - gamma) * (1-n)^(-sigma)/(1-tau_i) +gamma*c^(-sigma)*w/(1+tau_c);
% Euler Equation (EE)
EE = 1 - beta * ((1-tau_i)*q + 1 - delta);
% Aggregate Resource Constraint (ARC)
ARC = q * k + w * n - delta * k - c;
% Resource constraint for output
Wage = w - (1-alpha)*A * k^alpha * n^(- alpha);
% Capital accumulation equation (capital steady-state implies i = delta * k)
Interest = q - alpha*A * k^(alpha-1) * n^(1- alpha);
% Return system of equations
F = [LC; EE; ARC; Wage; Interest];
end
% Call the main function to solve the steady-state model