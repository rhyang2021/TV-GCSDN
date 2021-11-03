function [LLF,likelihoods, Ht, errors] = arma_bekk_mvgarch_likelihood4RepeatTimeVary(parameters, data, weight, window, p, q, Nr, Nl)
% input: paramter vector
%          data      -- time series
%          p         -- ar_order
%         q         -- arch_order
%         Nr, Nl  -- number of repeat experiments and the index of the measurements for each
%         experiment
% output: LLF  -- log likelihood function
%            likelihoods --- log likelihood function for each time point
%            Ht -- conditional variances
%          err -- residuals
[T,k] = size(data);
m = max(p,q);
errors = zeros(T,k); % the first m errors are zeros, since we are calculating the conditional QML
Ht = zeros(k,k,T);
LLF = 0;
likelihoods = zeros(T,1);

A = parameters(1 : k*k*p);
C = parameters(k*k*p+1 : k*k*p+k*(k+1)/2);
B = parameters(k*k*p+k*(k+1)/2+1 : end);
tempA = zeros(k,k,p);
tempB = zeros(k,k,q);
for i=1:p
    tempA(:,:,i) = reshape(A((k*k*(i-1)+1):(k*k*i)),k,k);
end
for i=1:q
    tempB(:,:,i) = reshape(B((k*k*(i-1)+1):(k*k*i)),k,k);
end
A = tempA;
B = abs(tempB);
C = ivech(C);
C = tril(C);
const = C*C';
%%%%%%%%%%%%%%%%%%%%%%%%%
%% call mex32
%%%%%%%%%%%%%%%%%%%%%%%%%
% %% prepare the vectors for mex32
% Tmax = 25000; Dmax = 20; pmax = 20; qmax = 20;
% data1 = zeros(Tmax, Dmax);                data1(1:T,1:k) = data;
% A1 = zeros(Dmax, Dmax, pmax);          A1(1:k, 1:k, 1:p) = A;
% B1 = zeros(Dmax, Dmax, qmax);          B1(1:k, 1:k, 1:q) = B;
% const1 = zeros(Dmax, Dmax);              const1(1:k, 1:k) = const;
%  [e, h] = armabekkllf(m, T, data1, A1, B1, const1, p, q, k);
%
% errors = e(inx_con,1:k);
% Ht = h(1:k, 1:k, inx_con);
% for i = 1 : size(inx_con,2)
%     likelihoods(i) = k*log(2*pi)+(log(det(Ht(:,:,i))) + errors(i,:)*Ht(:,:,i)^(-1)*errors(i,:)');
% end
% for i = 1 : size(inx_con,2)
%     LLF = LLF+likelihoods(i);
% end
%%%%%%%%%%%%%%%%%%%%%%%%%

for i = 1 : Nr
    for j = Nl(i,1)+m : Nl(i,2)
        errors(j,:) = data(j,:) - data(j-1,:) * A(:,:,1);
        for l = 2 : p
            errors(j,:) = errors(j,:)- data(j-l,:) * A(:,:,l);
        end
    end
end
uncond = cov(errors);
for i = 1 : Nr
    [row,~] = find(window==i);
    weight_temp = weight(row);
    for j = Nl(i,1) : Nl(i,2)
        if j < Nl(i,1)+m
            Ht(:,:,j) = uncond;
            % for conditional likelihood, the first m data points should be
            % excluded from the calculation of LLF
            % set them to zero
        else
            Ht(:,:,j) = const;
            for l = 1 : q
                Ht(:,:,j) = Ht(:,:,j) + B(:,:,l)*(data(j-l,:))'*(data(j-l,:))*B(:,:,l)';
            end
            likelihoods(j) = k*log(2*pi)+(log(det(Ht(:,:,j))) + errors(j,:)*Ht(:,:,j)^(-1)*errors(j,:)');
            LLF = LLF + likelihoods(j) * weight_temp;
        end
    end
end

% % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % input: m, T, data, A, B, const, p, q, k
% % % % output: errors, Ht, likelihoods, LLF
% parfor i = 1+m : T
%     errors(i,:) = data(i,:) - data(i-1,:) * A(:,:,1);
%     for j = 2 : p
%         errors(i,:) = errors(i,:)- data(i-j,:) * A(:,:,j);
%     end
% end
% uncond = cov(errors);
% for i = 1:m % the first m Ht's are the unconditional variance
%     Ht(:,:,i) = uncond;
% end
% parfor i = m+1 : T;
%     Ht(:,:,i) = const;
%     for j = 1 : q
% %          Ht(:,:,i) = Ht(:,:,i) + B(:,:,j)*(errors(i-j,:))'*(errors(i-j,:))*B(:,:,j)';
%         Ht(:,:,i) = Ht(:,:,i) + B(:,:,j)*(data(i-j,:))'*(data(i-j,:))*B(:,:,j)';
%     end
%     likelihoods(i) = k*log(2*pi)+(log(det(Ht(:,:,i))) + errors(i,:)*Ht(:,:,i)^(-1)*errors(i,:)');
% end
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% alpha = 10e7;
% tempA = zeros(k,k);
% for i = 1 : p
%     tempA(:,:) = A(:,:,i) + tempA;
% end
% if stationary_constraint(parameters, p, q, k, 0, 0) < 0
%     LLF = 0.5*(LLF);
% else
%     LLF = 1e20;
% end
LLF = 0.5*(LLF);
likelihoods = 0.5*likelihoods;
if isnan(LLF)
    LLF = 1e6;
end