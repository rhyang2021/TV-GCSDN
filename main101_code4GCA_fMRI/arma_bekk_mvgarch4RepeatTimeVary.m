function output  = arma_bekk_mvgarch4RepeatTimeVary(data, weight, window, ar_order,bekk_order, Nr, Nl, ARMABEKKoptions)
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
[newA, newC, newB] = initialparaforARBEKK(data, k, ar_order, bekk_order);
newA = reshape(newA, k*k*ar_order, 1);
newB = reshape(newB, k*k*bekk_order, 1);
startingparameters = [newA;newC;newB];

kx = 0;
ky = 0;
Inifeasible = stationary_constraint(startingparameters, ar_order, bekk_order, k, kx, ky);
if Inifeasible > 0    
    newB1 = newB * 0;
    startingparameters = [newA;newC;newB1];
    Inifeasible = stationary_constraint(startingparameters, ar_order, bekk_order, k, kx, ky);
    if Inifeasible > 0   
        newA1 = newA * 0;
        startingparameters = [newA1;newC;newB];
        Inifeasible = stationary_constraint(startingparameters, ar_order, bekk_order, k, kx, ky);
        if Inifeasible > 0   
            startingparameters = zeros(size(startingparameters));
            Inifeasible = stationary_constraint(startingparameters, ar_order, bekk_order, k, kx, ky);
            if Inifeasible > 0   
                disp('fail to find a feasible initial solution');
            end
        end
    end    
end

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
% newA = reshape(newA, k*k*ar_order, 1);
% CChol = vech(newC);
% newB = reshape(newB, k*k*bekk_order, 1);
% startingparameters = [newA;CChol;newB];
% startingparameters = [-1.52283853576517,1.64845102075373,-0.740879891502700,-0.271970708999833,-0.141059708352158,-0.142788627569226,0.382426644481709,-0.852552718410666,0.0511622637371538,-1.68253279382819,-1.44060388615859,-0.903321467896220,0.557354367119823,1.17873267303344,-0.859945968969715;];
%% fit the full model by minimizing the llfn
if nargin<=7 || isempty(ARMABEKKoptions)
    options=optimoptions('patternsearch');
else
    options = ARMABEKKoptions;
end
ObjectFunction = @(parameters)arma_bekk_mvgarch_likelihood4RepeatTimeVary(parameters, data, weight, window, ar_order, bekk_order, Nr, Nl);
ConstraintFunction=@(parameters)stationary_constraint(parameters,ar_order, bekk_order, k, kx, ky);
parameters = patternsearch(ObjectFunction, startingparameters, [],[],[],[],[],[], ConstraintFunction, options);
%%
[loglikelihood,likelihoods,Ht, errors] = arma_bekk_mvgarch_likelihood4RepeatTimeVary(parameters, data, weight, window, ar_order, bekk_order, Nr, Nl);
loglikelihood = -loglikelihood;
likelihoods = -likelihoods;
output.Ht = Ht;
output.LLF = loglikelihood;
output.likelihoods = likelihoods;
output.parameters = parameters;
output.errors = errors;

