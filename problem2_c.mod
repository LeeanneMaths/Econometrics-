% Declare variables and exogenous shocks
var c k l n i q w T G Y;  
varexo A tau_I;

% Set parameters
parameters beta gamma sigma alpha delta tau_c;
beta = 0.99; 
gamma = 0.3; 
sigma = 2; 
alpha = 0.33; 
delta = 0.025; 
tau_c = 0.1;

% Model equations
model;
    c^(-sigma)/(1+tau_c) = beta*c(+1)^(-sigma)/(1+tau_c)*((1-tau_I)*q + 1 - delta);
    gamma*c^(-sigma)/(1+tau_c) = (1-gamma)*l^(-sigma)/((1-tau_I)*w);
    (1-tau_I)*(q*k(-1)+w*n)+(1-delta)*k(-1)+ T = (1+tau_c)*c + k;
    w = (1-alpha)*A*k(-1)^alpha*n^(-alpha);
    q = alpha*A*k(-1)^(alpha-1)*n^(1-alpha);
    i = delta*k(-1);
    T = G;
    G = tau_c*c + tau_I*(q*k(-1) + w*n);
    1 = n + l;
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
    tau_I = 0.15;
end;
steady;

% Final steady state after TFP shock
endval;
    A = 0.95;  % Lowered TFP
end;
steady;

% Set up perfect foresight simulation
perfect_foresight_setup(periods = 198);

% Define shocks to the TFP
shocks;
var A;
periods 1:10;
values 1;
end;

% Solve perfect foresight simulation
perfect_foresight_solver;

% Extract and plot the simulated results
time = 1:198;
output = oo_.endo_simul(strmatch('Y', M_.endo_names, 'exact'), :);
capital = oo_.endo_simul(strmatch('k', M_.endo_names, 'exact'), :);
consumption = oo_.endo_simul(strmatch('c', M_.endo_names, 'exact'), :);
employment = oo_.endo_simul(strmatch('n', M_.endo_names, 'exact'), :);
investment = oo_.endo_simul(strmatch('i', M_.endo_names, 'exact'), :);
welfare = oo_.endo_simul(strmatch('T', M_.endo_names, 'exact'), :);
wages = oo_.endo_simul(strmatch('w', M_.endo_names, 'exact'), :);

% Plotting the results for output, consumption, investment, and welfare
figure(1);
subplot(2,2,1);
plot(yv-y0);
title('Output');
subplot(2,2,2);
plot(cv-y0);
title('Consumption');
subplot(2,2,3);
plot(iv-i0);
title('Investment');
subplot(2,2,4);
plot(tv-t0);
title('Fiscal revenues');
print -depsc fig_model2a_tauC_1a.eps
print -dpdf fig_model2a_tauC_1a.pdf
    
    
figure(2);
subplot(2,2,1);
plot(kv-k0);
title('Capital stock');
subplot(2,2,2);
plot(nv-n0);
title('Worked hours');
subplot(2,2,3);
plot(rv-r0);
title('Interest rate');
subplot(2,2,4);
plot(wv-w0);
title('Wage');
    
print -depsc fig_model2a_tauC_1b.eps
print -dpdf fig_model2a_tauC_1b.pdf


% Save figure 2
print -depsc fig_model_output_2.eps
print -dpdf fig_model_output_2.pdf
