clear all;
close all;
clc;
% assign values
beta ==0.95^30;
sigma = 2;
A = 1;
alpha = 0.33;
delta = 1-(1-0.05)^30

initial 
x0 = [.1..1,.1,.1,1,1,1,1]

% put the defined function into fsolve

[c_1,c_2,s,w,r,K,N,Y]= task1(beta,sigma,A,alpha,delta,