% Declare variables and exogenous shocks
var c k l n i q w T G Y;  
varexo A tau_I;

% Set parameters
parameters beta gamma sigma alpha delta tau_c;
beta = 0.99;  % Discount factor
gamma = 0.3;  % Labor supply preference
sigma = 2;  % Intertemporal elasticity of substitution
alpha = 0.33;  % Capital share
delta = 0.025;  % Depreciation rate
tau_c = 0.1;  % Consumption tax

% Model equations
model;
    % Euler equation for consumption
    c^(-sigma)/(1+tau_c) = beta*c(+1)^(-sigma)/(1+tau_c)*((1-tau_I)*q + 1 - delta);
    
    % Labor-leisure tradeoff
    gamma*c^(-sigma)/(1+tau_c) = (1-gamma)*l^(-sigma)/((1-tau_I)*w);
    
    % Resource constraint / government budget constraint
    (1-tau_I)*(q*k(-1)+w*n)+(1-delta)*k(-1)+ T = (1+tau_c)*c + k;
    
    % Wage and rental rate of capital
    w = (1-alpha)*A*k(-1)^alpha*n^(-alpha);
    q = alpha*A*k(-1)^(alpha-1)*n^(1-alpha);
    
    % Investment equals depreciation
    i = delta*k(-1);
    
    % Government budget equation
    T = G;
    G = tau_c*c + tau_I*(q*k(-1) + w*n);
    
    % Labor supply constraint
    1 = n + l;
    
    % Production function
    Y = A*k(-1)^alpha*n^(1-alpha);
end;

% Initial steady state
initval;
    c = 1; 
    k = 1; 
    l = 1; 
    n = 1; 
    i = 1; 
    q = 1; 
    w = 1; 
    T = 1; 
    G = 1; 
    Y = 1;
    A = 1;   % Initial TFP
    tau_I = 0.15;  % Initial tax rate at 15%
end;
steady;

% Introduce the negative TFP shock in periods 1 to 10
shocks;
var A;
periods 1:10;  % Apply the TFP shock over these periods
values 0.95;  % TFP drops from 1 to 0.95
end;

% Apply the tax rate cut after the TFP shock from period 11 onwards
shocks;
var tau_I;
periods 11:198;  % Tax cut starts from period 11
values 0.10;     % New tax rate = 10%
end;

% Set up perfect foresight simulation
perfect_foresight_setup(periods = 198);

% Solve perfect foresight simulation
perfect_foresight_solver;

% Extract the simulated results and ensure correct dimensions
time = 1:198;  % Define the time periods
output = oo_.endo_simul(strmatch('Y', M_.endo_names, 'exact'), 1:198)';  % Truncate to 198 periods and transpose
capital = oo_.endo_simul(strmatch('k', M_.endo_names, 'exact'), 1:198)';  % Truncate to 198 periods and transpose
consumption = oo_.endo_simul(strmatch('c', M_.endo_names, 'exact'), 1:198)';  % Truncate to 198 periods
employment = oo_.endo_simul(strmatch('n', M_.endo_names, 'exact'), 1:198)';  % Truncate to 198 periods
investment = oo_.endo_simul(strmatch('i', M_.endo_names, 'exact'), 1:198)';  % Truncate to 198 periods
welfare = oo_.endo_simul(strmatch('T', M_.endo_names, 'exact'), 1:198)';  % Truncate to 198 periods
wages = oo_.endo_simul(strmatch('w', M_.endo_names, 'exact'), 1:198)';  % Truncate to 198 periods

% Plotting the results for output, consumption, investment, and welfare
figure(1);
subplot(2,2,1);
plot(time, output, 'LineWidth', 1.5);  % Plot 'output' for 198 periods
title('Output');
xlabel('Periods');
ylabel('Output');
grid on;

subplot(2,2,2);
plot(time, consumption, 'LineWidth', 1.5);  % Plot 'consumption' for 198 periods
title('Consumption');
xlabel('Periods');
ylabel('Consumption');
grid on;

subplot(2,2,3);
plot(time, investment, 'LineWidth', 1.5);  % Plot 'investment' for 198 periods
title('Investment');
xlabel('Periods');
ylabel('Investment');
grid on;

subplot(2,2,4);
plot(time, welfare, 'LineWidth', 1.5);  % Plot 'welfare' (Fiscal revenues)
title('Fiscal Revenues (Welfare)');
xlabel('Periods');
ylabel('Welfare');
grid on;

% Save figure 1
print -depsc fig_tax_cut_output_1.eps
print -dpdf fig_tax_cut_output_1.pdf


% Plotting the results for capital, employment, rental rate, and wages
figure(2);
subplot(2,2,1);
plot(time, capital, 'LineWidth', 1.5);  % Plot 'capital' for 198 periods
title('Capital Stock');
xlabel('Periods');
ylabel('Capital Stock');
grid on;

subplot(2,2,2);
plot(time, employment, 'LineWidth', 1.5);  % Plot 'employment' for 198 periods
title('Employment (Hours Worked)');
xlabel('Periods');
ylabel('Employment');
grid on;

subplot(2,2,3);
rental_rate = oo_.endo_simul(strmatch('q', M_.endo_names, 'exact'), 1:198)';  % Plot 'rental rate' for 198 periods
plot(time, rental_rate, 'LineWidth', 1.5);
title('Rental Rate of Capital');
xlabel('Periods');
ylabel('Rental Rate');
grid on;

subplot(2,2,4);
plot(time, wages, 'LineWidth', 1.5);  % Plot 'wages' for 198 periods
title('Wages');
xlabel('Periods');
ylabel('Wages');
grid on;

% Save figure 2
print -depsc fig_tax_cut_output_2.eps
print -dpdf fig_tax_cut_output_2.pdf
