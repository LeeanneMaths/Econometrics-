clear all; close all;

disp('--- New run ------');
% Parameters
% Exogenous variables: {beta, sigma, A, alpha, delta}
beta    = 0.7385; % Time discount factor over 15 years
sigma   = 2;       % Risk aversion parameter
A       = 1;       % Productivity factor
alpha   = 0.33;    % Capital share in production
delta   = 0.5367;  % Depreciation rate over 15 years
h_1 = 1;           % Labor supply of agent 1
h_2 = 1.5;         % Labor supply of agent 2

% Initial values for endogenous variables: {c1, c2, c3, c4, s1, s2, s3, w, r, K, N, Y}
X0 = [0.3, 0.3, 0.3, 0.3, 0.1, 0.5, 0.3, 0.5, 1, 1, 2.5, 1];

% Call the fsolve function to solve the system of GE equations
[c_1, c_2, c_3, c_4, s_1, s_2, s_3, H, w, r, q, K, N, Y] = sol_GEsys_f(beta, sigma, A, alpha, delta, h_1, h_2, X0);

disp('---- Results---------------- ');
disp(['Y    =' num2str(real(Y))]); % Ensure only real part is displayed
disp(['K    =' num2str(real(K))]);
disp(['N    =' num2str(real(N))]);
disp(['R    =' num2str(real(1 + r))]); % Corrected to display 1 + r
disp(['w    =' num2str(real(w))]);
disp(['q    =' num2str(real(q))]);
disp(['H    =' num2str(H)]); % H should remain real

% Output consumption and savings values
disp(['c1   =' num2str(real(c_1))]);
disp(['c2   =' num2str(real(c_2))]);
disp(['c3   =' num2str(real(c_3))]);
disp(['c4   =' num2str(real(c_4))]);
disp(['s1   =' num2str(real(s_1))]);
disp(['s2   =' num2str(real(s_2))]);
disp(['s3   =' num2str(real(s_3))]);
disp('-------------------------- ');

% Function to solve the system of GE equations
function [c_1, c_2, c_3, c_4, s_1, s_2, s_3, H, w, r, q, K, N, Y] = sol_GEsys_f(beta, sigma, A, alpha, delta, h_1, h_2, X0)
    % 5 exogenous variables: {beta, sigma, A, alpha, delta} - parameters
    % 12 endogenous variables: {c1, c2, c3, c4, s1, s2, s3, w, r, K, N, Y} - determined in the model

    options = optimset('Display', 'off', 'TolFun', 1e-9, 'TolX', 1e-9); % Increase precision tolerance
    X = fsolve(@cFOCs_f, X0, options); % Call fsolve to solve the function cFOCs_f

    % Assign values to the output variables
    c_1 = X(1);
    c_2 = X(2);
    c_3 = X(3);
    c_4 = X(4);
    s_1 = X(5);
    s_2 = X(6);
    s_3 = X(7);
    w   = X(8);
    r   = X(9);
    K   = X(10);
    N   = X(11);
    Y   = X(12);

    % Define the total labor supply H
    H = h_1 + h_2;

    % Define q based on the capital-labor ratio
    q = alpha * A * K^(alpha - 1) * N^(1 - alpha);

    % Nested function to define the system of equations
    function F = cFOCs_f(X)
        % Define variable names: {c1, c2, c3, c4, s1, s2, s3, w, r, K, N, Y}
        c_1 = X(1); % Consumption 1
        c_2 = X(2); % Consumption 2
        c_3 = X(3); % Consumption 3
        c_4 = X(4); % Consumption 4
        s_1 = X(5); % Savings 1
        s_2 = X(6); % Savings 2
        s_3 = X(7); % Savings 3
        w   = X(8); % Wage  
        r   = X(9); % Interest rate
        K   = X(10); % Capital
        N   = X(11); % Labor  
        Y   = X(12); % Output

        % System of equilibrium condition equations
        F(1) = beta * c_2^(-sigma) - c_1^(-sigma) / (1 + r); % Euler equation for 1st period
        F(2) = beta * c_3^(-sigma) - c_2^(-sigma) / (1 + r); % Euler equation for 2nd period
        F(3) = beta * c_4^(-sigma) - c_3^(-sigma) / (1 + r); % Euler equation for 3rd period
        F(4) = c_1 + c_2 / (1 + r) + c_3 / (1 + r)^2 + c_4 / (1 + r)^3 - h_1 * w - h_2 * w / (1 + r); % Lifetime budget
        F(5) = s_1 + c_1 - h_1 * w; % Savings for 1st period
        F(6) = s_2 + c_2 - h_2 * w - (1 + r) * s_1; % Savings for 2nd period
        F(7) = s_3 + c_3 - (1 + r) * s_2; % Savings for 3rd period
        F(8) = c_4 - (1 + r) * s_3; % Savings for 4th period
        F(9) = w - (1 - alpha) * A * K^alpha * N^(-alpha); % Wage equation
        F(10) = r - alpha * A * K^(alpha - 1) * N^(1 - alpha) + delta; % Interest rate equation
        F(11) = N - 2.5; % Labor market equilibrium (fixed labor supply)
        F(12) = K - s_1 - s_2 - s_3; % Capital accumulation
        F(13) = Y - A * K^alpha * N^(1 - alpha); % Production function
    end
end
