function output  = arma_bekk_mvgarchXY4RepeatTimeVary(data, weight, window, ar_order,bekk_order, indexX, indexY, Nr, Nl,para_x,para_y)
%% QMLE 
% exactly, it is mulivariate of ar_arch model at the moment
% model
% X(t) = A(i)X(t-i) + (CC' + B X(t-i) X(t-i)' B')^(1/2) e(t)
% three sequences involved:
% X(t) -- the observations
% E(t) -- the residues of ARMA model 
% H(t) -- the conditional variances
% the parameters are estimated by the conditional likelyhood function from
% max(order) to T
% llfn = -0.5ln|H(t)| - 0.5 E(t)'H(t)^(-1)E(t)
% it is the same to minimize -llfn

% input:
%         data -- T by k time series
%         ar_order -- k by k integer matrix specifying the lags of
%         dimension i for dimension j
%         bekk_order -- k by k integer matrix specifying the lags of
%         dimension i for dimansion j
%         Nr, Nl  -- number of repeat experiments and the index of the measurements for each
%         experiment
%         ARMABEKKoptions -- 
% output:
%         output.llfn  --- log likelihood function from max(order) to T
%         output.parameters -- ARMA, ARCH
%         AR(i) = reshape(parameters((i-1)*k^2+i*k^2))
%         C = ivech(paramters(k^2*LagAR+1 : k^2*LagAR+1+k(k+1)/2))
%             start = k^2*LagAR+1+k(k+1)/2);
%         ARCH(i) = reshape(parameters(start+1+(i-1)*k^2:start+1+i*k^2 ))
%         output.residues -- E(t)
%         output.H -- H(t)
%  by now, we are going to use bootstrap to estimate the covariance of the
%  parameters

k = size(data,2);
%% estimate the initial parameters by one dimensional model
% fit an one dimensional arma_garch model as the intial paramters for
% amra_bekk
% newA = zeros(k, k, ar_order);
% newC = zeros(k,k);
% newB = zeros(k, k, bekk_order);
% for dim = 1 : k
%     spec_fit = garchset('R', ar_order, 'Q', bekk_order, 'Display','off');
%     clear tCoeff;
%     [tCoeff, tErrors, tLLF] = garchfit(spec_fit, data(:,dim));
%     for i  = 1 : ar_order
%         newA(dim, dim, i) = tCoeff.AR(i)'; % we are using row vector
%     end
%     newC(dim, dim) = tCoeff.K;
%     for i = 1 : bekk_order
%         newB(dim,dim, i) = tCoeff.ARCH(i)'; % we are using row vector
%     end
% end
%newA = reshape(newA, k*k*ar_order, 1);
% [newA, newC, newB] = initialparaforARBEKK(data, k, ar_order, bekk_order);
% newC = ivech(newC);
% newB = reshape(newB, k,k,bekk_order);

kx = size(indexX,2);
ky = size(indexY,2);
k = kx + ky;
para_xx=reshapeparas(para_x, ar_order, bekk_order, kx);
para_yy=reshapeparas(para_y, ar_order, bekk_order, ky);
A11=para_xx.A;
A22=para_yy.A;
C11=para_xx.C;
C22=para_yy.C;
newA=[A11,0;0,A22];
newCx=C11;
newCy=C22;
newBX=[para_xx.B,0];
newBY=[0,para_yy.B];
startingparameters = [reshape(newA, k*k*ar_order, 1);vech(newCx);vech(newCy);reshape(newBX, kx*k*bekk_order,1);reshape(newBY, ky*k*bekk_order, 1)];
Inifeasible = stationary_constraint(startingparameters, ar_order, bekk_order, k, kx, ky);
if Inifeasible > 0    
    newBX1 = newBX * 0;
    newBY1 = newBY * 0;
    startingparameters = [newA;vech(newCx);vech(newCy);reshape(newBX1, kx*k*bekk_order,1);reshape(newBY1, ky*k*bekk_order, 1)];
    Inifeasible = stationary_constraint(startingparameters, ar_order, bekk_order, k, kx, ky);
    if Inifeasible > 0   
        newA1 = newA * 0;
        startingparameters = [newA1;vech(newCx);vech(newCy);reshape(newBX, kx*k*bekk_order,1);reshape(newBY, ky*k*bekk_order, 1)];
        Inifeasible = stationary_constraint(startingparameters, ar_order, bekk_order, k, kx, ky);
        if Inifeasible > 0   
            startingparameters = zeros(size(startingparameters));
            Inifeasible = stationary_constraint(startingparameters, ar_order, bekk_order, k, kx, ky);
            if Inifeasible > 0   
                'fail to find a feasible initial solution'
            end
        end
    end    
end
%% fit the full model by minimizing the llfn
if nargin<=11 || isempty(ARMABEKKoptions)
    options=optimoptions('patternsearch');
else
    options = ARMABEKKoptions;
end
ObjectFunction = @(parameters)arma_bekk_mvgarch_likelihoodXY4RepeatTimeVary(parameters, data, weight, window, ar_order, bekk_order, kx, ky, Nr, Nl);
ConstraintFunction=@(parameters)stationary_constraint(parameters,ar_order, bekk_order, k, kx, ky);
parameters = patternsearch(ObjectFunction, startingparameters, [],[],[],[],[],[], ConstraintFunction, options);
%%
[loglikelihood,likelihoods,Ht, errors] = arma_bekk_mvgarch_likelihoodXY4RepeatTimeVary(parameters,data, weight, window, ar_order,bekk_order, kx, ky, Nr, Nl);
loglikelihood=-loglikelihood;
likelihoods=-likelihoods;
%% 
outputLLF = arma_bekk_mvgarch_likelihoodXY4Repeat4XTimeVary(parameters, data, weight, window, ar_order,bekk_order, kx, ky, Nr, Nl, indexX, indexY);
output.Ht = Ht;
output.LLF = loglikelihood;
output.likelihoods = likelihoods;
output.parameters = parameters;
output.errors = errors;
output.LLF_x = -outputLLF.LLF_x;
output.LLF_y = -outputLLF.LLF_y;
output.likelihoods_x = outputLLF.likelihoods_x;
output.likelihoods_y = outputLLF.likelihoods_y;
