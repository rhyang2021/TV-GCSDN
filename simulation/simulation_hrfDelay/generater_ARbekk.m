function [x, y] = generater_ARbekk(corr,BX,BY,constx,consty,timepoint,l)
% Input: 
%   Corr: para for AR
%   BY: para for SDN [sqrt(0.1),0];
%   BX: para for SDN [sqrt(0.1),sqrt(para_b)];
%   l: neuronal delay
% Output:
%   [x,y]: Simulated time-varying time series
% Instruction:
%   time series: X(t) = A*X(t-l) + Ht*U(t), Ht = Const+sqrt(B*X(t-l)'*X(t-l)*B'),
%   U(t) is Gassian white noise.
%   Here we discard first 5000 time points to get a satble time series.
x = zeros(1,timepoint+5000);
y = zeros(1,timepoint+5000);
A = corr;
for i=l+1:timepoint+5000
    Z = [x(i-l),y(i-l)]'*[x(i-l),y(i-l)];
    Htx = BX*Z*BX' + constx;
    Hty = BY*Z*BY' + consty;
    x(i) = x(i-l)*A(1,1) + y(i-l)*A(1,2) + sqrt(Htx)*randn(1);
    y(i) = x(i-l)*A(2,1) + y(i-l)*A(2,2) + sqrt(Hty)*randn(1);
end
x = x(5001:end);
y = y(5001:end);