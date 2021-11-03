function output = objectfunction4hrf(para,y,XB,lambda,B)
% Input:
%   y - bold-signals of each regions
%   XB - design matrix(simulation conv hrf basis)
%   B - hrf basis
%   para
%   h - para(1:order):parameters for hrf(3-basis)
%   beta - para(order+1:order+nconditions):activations of 3 conditions 
%   r - para for drift regressors 
%   lambda - para for L2
T = size(y,1);
trend_design = ones(T,1);
order = size(B,2);
nconditions = size(XB,2)/order;
[Q,~] = qr(XB); % the Euclidean norm is invariant to orthogonal transformations
XB = Q'*XB; % reduces the size of the design matrix to a square triangular matrix of size dk ¡Á dk (instead of n ¡Á dk) 
y = Q'*y; % reduces the explained variable y to a vector of size kd (instead of n).
h = para(1:order,1);
beta = para(order+1:order+nconditions,1);
r = para(order+nconditions+1:order+nconditions+1,1);
w = y-XB*(kron(beta,h)) - trend_design*r;
output = 1/2*(w'*w) - lambda*(B*h)'*(B*h);

