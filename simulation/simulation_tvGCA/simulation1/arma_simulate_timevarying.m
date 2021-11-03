function data = arma_simulate_timevarying(t,k,kx,ky,A,u1,u2, p)
% INPUTS:
%     t             - Length of data serie to prouce
%     k             - Dimension of series to produce
%     kx, ky        - Dim for x and y
%     p             - ar_order
%     q             - bekk_order
%     parameters    - given by functions 
%     u1,u2         - coefficient
% 
% OUTPUTS:
%     data          - A t by k matrix of zero mean residuals
t=t+500;
%% Reshape the parameters 
% input: k,kx,ky,p,q,parameters
% output: A, B, const
%% first m data
% use arma model to get the initals 
A0(:,:,1) = eye(k);
for i = 2 : 1+p
    A0(:,:,i) = -A(0,i-1,u1,u2)'; % t = 0
end
m0 = idarx(A0, [], 1);
e = iddata([],  randn(1000+t,k));
temp = sim(m0, e);
m = p;
data = temp.OutputData(500:end,:);

%% simulation
for i=m+1:t+m
    data(i,:) = zeros(1,k);
    for j=1:p
        data(i,:) = data(i,:) + data(i-j,:) * A(i,j,u1,u2) + 0.5*randn(1,k);
    end
end
data=data(1:t-500,:);
