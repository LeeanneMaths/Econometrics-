function[c_1,c_2,s,w,r,K,N,Y]= task1(beta,sigma,A,alpha,delta,x0);

%options
options = optimset('Display','off');
%fsolve
fsolve(@task1q, x0,options)

%function
function F = task1_sub(x)
            unpack
            c_1=x(1);
            c_2= x(2);
            s = x(3);
            w = x(4);
            r = x(5);
            K = x(6);
            N = x(7);
            Y = x(8);
            %define the system
            F(1) = beta*c_2^(-sigma)-c_1^(-sigma)/(1+r);
            F(2) = c_1+c_2/(1+r)-w;
            F(3) = s+c_1-w;
            F(4) = w-

         