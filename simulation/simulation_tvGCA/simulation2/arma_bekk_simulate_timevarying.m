function [data, Ht] = arma_bekk_simulate_timevarying(t,k,kx,ky,A, constx, consty, BX, BY, p,q)
% INPUTS:
%     t             - Length of data serie to prouce
%     k             - Dimension of series to produce
%     kx, ky        - Dim for x and y
%     p             - ar_order
%     q             - bekk_order
%     parameters    - given by functions 
% 
% OUTPUTS:
%     data          - A t by k matrix of zero mean residuals
%     Ht            - A k x k x t 3 dimension matrix of conditional covariances

t=t+500;

%% Reshape the parameters 
% input: k,kx,ky,p,q,parameters
% output: A, B, const

%% first m data
% use arma model to get the initals 
A0(:,:,1) = eye(k);
for i = 2 : 1+p
    A0(:,:,i) = -A(0,i-1)'; % t = 0
end
m0 = idarx(A0, [], 1);
e = iddata([],  randn(1000+t,k));
temp = sim(m0, e);
m = max(p,q);
data = temp.OutputData(500:end,:);

%% simulation
for i = m+1:t+m
    data(i,:) = zeros(1,k);
    for j=1:p
        data(i,:) = data(i,:) + data(i-j,:) * A(i-500,j);
    end    
    Htx(:,:,i) = constx;
    if ky > 0
        Hty(:,:,i) = consty;
    end
    for j=1:q
        Z = (data(i-j,:))'*(data(i-j,:));
        Htx(:,:,i) = Htx(:,:,i) + BX(i-500,j)* Z * BX(i-500,j)';
        if ky > 0 
            Hty(:,:,i) = Hty(:,:,i) + BY(i-500,j)* Z * BY(i-500,j)';
        end        
    end
    if ky > 0
        Ht(:,:,i) = [Htx(:,:,i), zeros(kx,ky); zeros(ky,kx), Hty(:,:,i)];
    else
        Ht(:,:,i) = Htx(:,:,i);
    end
    data(i,:) = data(i,:) + randn(1,k) * (Ht(:,:,i))^(0.5);
end
data=data(m+500:t+m-1,:);
Ht=Ht(:,:,m+500:t+m-1);