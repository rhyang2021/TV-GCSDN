function [LLF,likelihoods,Ht, errors]= arma_bekk_mvgarch_likelihoodXY4Repeat(parameters, data, p, q, kx, ky, Nr, Nl)
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

para_armabekk = reshapeparasXY(parameters, p, q, k, kx, ky);
A = para_armabekk.A;
BX = para_armabekk.BX;
BY = para_armabekk.BY;
constx = para_armabekk.constx;
consty = para_armabekk.consty;


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
    for j = Nl(i,1) : Nl(i,2)
        if j < Nl(i,1)+m
            Ht(:,:,j) = uncond;
         else   
             hx = constx;
             hy = consty;
             for l = 1 : q
                 Z = (data(j-l,:))'*(data(j-l,:));
                 hx = hx + BX(:,:,l)* Z * BX(:,:,l)';
                 hy = hy + BY(:,:,l)* Z * BY(:,:,l)';
             end
             Ht(:,:,j) = [hx,zeros(kx,ky); zeros(ky,kx),hy];
             likelihoods(j) = k*log(2*pi)+(log(det(Ht(:,:,j))) + errors(j,:)*Ht(:,:,j)^(-1)*errors(j,:)');
             LLF = LLF+likelihoods(j);
        end
    end
end
            

% %%%%%%%%%%%%%%%%%%%%%%%%%
% %% call mex32
% %%%%%%%%%%%%%%%%%%%%%%%%%
% % %% prepare the vectors for mex32
% Tmax = 25000; Dmax = 20; pmax = 20; qmax = 20;
% data1 = zeros(Tmax, Dmax);                data1(1:T,1:k) = data;
% A1 = zeros(Dmax, Dmax, pmax);          A1(1:k, 1:k, 1:p) = A;
% BX1 = zeros(Dmax, Dmax, qmax);          BX1(1:kx, 1:k, 1:q) = BX;
% BY1 = zeros(Dmax, Dmax, qmax);          BY1(1:ky, 1:k, 1:q) = BY;
% constx1 = zeros(Dmax, Dmax);              constx1(1:kx, 1:kx) = constx;
% consty1 = zeros(Dmax, Dmax);              consty1(1:ky, 1:ky) = consty;
% 
% [e, hx, hy, uncond] = armabekkllfxy(m, T, data1, A1, BX1, BY1, constx1, consty1, p, q, k);
% errors = e(inx_con,1:k);
% % uncond = uncond(1:k,1:k);
% Htx = hx(1:kx, 1:kx, inx_con);
% Hty = hy(1:ky, 1:ky, inx_con);
% % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % input: m, T, data, A, BX,BY, constx,consty, p, q, k
% % % % % output: e, hx, hy, uncond
% % for i = 1+m : T
% %     errors(i,:) = data(i,:) - data(i-1,:) * A(:,:,1);
% %     for j = 2 : p
% %         errors(i,:) = errors(i,:)- data(i-j,:) * A(:,:,j);
% %     end
% % end
% % uncond = cov(errors);
% % for i = m+1 : T;
% %     Htx(:,:,i) = constx;
% %     Hty(:,:,i) = consty;
% %     for j = 1 : q
% %         Z = (data(i-j,:))'*(data(i-j,:));
% %         Htx(:,:,i) = Htx(:,:,i) + BX(:,:,j)* Z * BX(:,:,j)';
% %         Hty(:,:,i) = Hty(:,:,i) + BY(:,:,j)* Z * BY(:,:,j)';
% %     end
% % end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % for i = 1:m % the first m Ht's are the unconditional variance
% %     Ht(:,:,i) = uncond;
% % end
% Ht = zeros(k,k,size(inx_con, 2)); 
% for i = 1 : size(inx_con, 2)
% %     Ht(:,:,i) = [Htx(:,:,i), zeros(kx,ky); zeros(ky,kx), Hty(:,:,i)];
%     Ht(1:kx,1:kx,i) = Htx(:,:,i);
%     Ht(kx+1:kx+ky,kx+1:kx+ky,i) = Hty(:,:,i);
%     likelihoods(i) = k*log(2*pi)+(log(det(Ht(:,:,i))) + errors(i,:)*Ht(:,:,i)^(-1)*errors(i,:)');
% end
% % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for i = 1 : size(inx_con,2)     
%     LLF = LLF+likelihoods(i);
% end

% if stationary_constraint(parameters, p, q, k, kx, ky) < 0
%     LLF = 0.5*(LLF);
% else
%     LLF = 1e20;
% end
LLF = 0.5*(LLF);
likelihoods = 0.5*likelihoods;
if isnan(LLF)
    LLF = 1e6;
end