clear all; close all;
tic
disp('--------- New run ---------');

% Parameter values
beta    = 0.7385;    % Discount factor (calibrated)
sigma   = 2;         % Risk aversion parameter
A       = 1;         % Productivity factor
alpha   = 0.33;      % Capital share
delta   = 0.5367;    % Depreciation rate (15 years)
h_1     = 1;         % Labor supply of agent 1
h_2     = 1.5;       % Labor supply of agent 2

% Initial labor supply and wage/interest rate
Nold    = 2.5;       % Initial labor supply
K       = 1;         % Start with a guess for capital (K is used instead of Kold)
w       = (1 - alpha) * A * K^alpha * Nold^(-alpha);    % Initial wage guess
R       = 1 + alpha * A * K^(alpha - 1) * Nold^(1 - alpha) - delta;  % Initial gross interest rate

% For iteration
error   = 100;
errorv  = 100;
iter    = 0;
itermax = 50;
tol     = 0.001;
update  = 0.5;

% Gauss-Seidel iteration loop
while (iter < itermax) && (error > tol)
    %------------------------------------
    % 1. Household problem: Solving with Lagrangian method for consumption and savings
    % Consumption in each period
    lambda_sig = (h_1*w + h_2*w / R) / ((1 + (1 / R) * (1 / (R * beta))^(-1 / sigma) + ...
                    (1 / R^2) * (1 / (R^2 * beta^2))^(-1 / sigma) + ...
                    (1 / R^3) * (1 / (R^3 * beta^3))^(-1 / sigma)));
    
    c_1 = lambda_sig;
    c_2 = lambda_sig * (1 / (R * beta))^(-1 / sigma);
    c_3 = lambda_sig * (1 / (R^2 * beta^2))^(-1 / sigma);
    c_4 = lambda_sig * (1 / (R^3 * beta^3))^(-1 / sigma);
    
    % Savings
    s_1 = h_1 * w - c_1;
    s_2 = h_2 * w + R * s_1 - c_2;
    s_3 = R * s_2 - c_3;  % Keep this line and remove the redundant one

    %------------------------------------
    % 2. Labor and capital market clearing
    N = 2.5;  % Fixed labor supply
    Knew = s_1 + s_2 + s_3;  % Total capital from savings
    
    % Convex update for capital to stabilize iteration
    K = update * K + (1 - update) * Knew;  % No Kold, use updated K
    
    %------------------------------------
    % 3. Firm's problem: Factor prices from firm's FOCs
    w = (1 - alpha) * A * K^alpha * N^(-alpha);  % Wage equation
    q = alpha * A * K^(alpha - 1) * N^(1 - alpha);  % Marginal product of capital
    r = q - delta;  % Interest rate (net of depreciation)
    R = 1 + r;  % Gross interest rate
    
    % Output
    Y = A * K^alpha * N^(1 - alpha);
    
    %------------------------------------
    % 4. Convergence check
    error = 100 * abs(Knew - K) / K;  % Error in percentage (new K compared to updated K)
    errorv = [errorv error];
    
    iter = iter + 1;  % Increment iteration count
end

% Display results
disp('---- Results---------------- ');
disp(['Y    = ' num2str(Y)]);
disp(['K    = ' num2str(K)]);
disp(['N    = ' num2str(N)]);
disp(['R    = ' num2str(R)]);  % Directly display 15-year rate without converting to annual
disp(['w    = ' num2str(w)]);
disp(['error = ' num2str(error)]);
disp('-------------------------- ');

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
