function [HRF,hrf,activation] = my_hrf(fmri_spec,subj,rois, xBF, fmri_data,mode)
% Input:
%   fmri_data: bold-signal for each subject and each region
%   xBF: 3-HRF basis, 'hrf (with time and dispersion derivatives)' in spm8
%   fmri_spec.onset: 3 conditions
%   fmri_spec.upsampling_factor: upsampling rate(32)
%   fmri_spec.timing.RT = 2 % in seconds
%   fmri_spec.nconditions = 3;
%   fmri_spec.datalength = datalength; % length of bold-signal
%   mode: method to calculate HRF('GLM')
% Output:
%   HRF: hrf for roi
%   hrf: paras for hrf basis
%   activation: activation for conditions
% Instructions:
%   'GLM': estimate n hrfs for n conditions.
%   y = XB*beta, y is a n * 1 vector, XB is the design matrix(n *
%   d), beta is a (n*d) * 1 vector, B * beta(1:d) is estimated hrf for condition 1.
%   If e = y - XB*beta is not gassian white noise, pre-whitening and use
%   GLM-AR(1) model.
%   'r1GLM': estimate 1 hrf and n activations for n conditions.
%   h,beta,w = argmin(1/2*(y-XB*vec(h*beta')-Z*w)^2), s.t -1 < max(B*h) < 1,
%   and B*h'*h_{ref} > 0.

y = fmri_data{subj}(:,rois);
lambda = 0.5;
% % % ----------------------------------------------------------------% % %
% step 0 account for sudden movement
move =  fmri_spec.motion{subj};
tmove = [0,0; sqrt(sum(diff(move(:,1:3)).^2,2)), ...
        sqrt(sum(diff(move(:,4:6)).^2,2))]; % the first scan get no movement
y = filtermovement(tmove', y');

% step 1:regress out motion
move_design =  [fmri_spec.motion{subj}, ones(size(fmri_spec.motion{subj},1),1)];
glmbeta1 = move_design \ y;
y = y - move_design * glmbeta1;

% step 2 normalization
y = y-mean(y);

% step 3: making event-train(one-hot)
U = my_get_ons(fmri_spec, subj);
% % % ----------------------------------------------------------------% % %
% step 4: design matrix(event train convolved with hrf basis)
X = my_hrf_conv(U, fmri_spec, xBF);
designmatrix = [];
for i = 1 : fmri_spec.nconditions
    designmatrix = [designmatrix, X{i}];
end
% % % ----------------------------------------------------------------% % %
% step 5: add trend f(x) = 1+x+x^2+x^3
T = size(y,1);
if strcmp(mode,'GLM') == 1
    trend_design = [ones(T,1),(1:T)', (1:T)'.^2, (1:T)'.^3];
    designmatrix = [designmatrix,trend_design];
end
XB = designmatrix; % sum of columns = nconditions * basis
B = xBF.bf;
d = size(B,2);
k = fmri_spec.nconditions;

% canonical HRF
RT = xBF.dt;
P = [6 16 1 1 6 0 32];
[hrf_ref,~] = spm_hrf(RT,P);
try
    hrf_ref = hrf_ref(1:size(B,1),1);
catch
    hrf_ref(end+1:size(B,1),:) = 0;
end
hrf_ref = hrf_ref / max(hrf_ref);
% % % ----------------------------------------------------------------% % %
% step 6: calculate hrf
if strcmp(mode,'GLM') == 1
    HRF = zeros(size(B,1),k);
    activation = zeros(k,1);
    hrf = zeros(d,k);
    beta = XB \ y;
    if size(beta,1) ~= d*k+4
        error(['beta = ',num2str(size(beta,1))]);
    end
    % Residual deviation test
    e = y - XB*beta;
    % PACF = parcorr(e);
    rho = e(2:end,1)'*e(1:end-1,:)/(e'*e);
    % pre-whitening
    y = (y - rho*[0;y(1:end-1,1)])/sqrt(1-rho^2);
    XB = (XB - rho*[zeros(1,size(XB,2));XB(1:end-1,:)])/sqrt(1-rho^2);
    beta = XB \ y;
elseif strcmp(mode,'r1GLM') == 1
    % linear constraint
    % -1< {Bh}_{i} < 1
    % k = fmri_spec.nconditions + 4th trend
    A = [B,zeros(size(B,1),k+1);-B,zeros(size(B,1),k+1)];
    b = ones(size(A,1),1);
    % optmization(l-bfgs)
    options= optimoptions('fmincon');
    options.Algorithm = 'interior-point';
    options.HessianApproximation = 'lbfgs';
    %options.LargeScale = 'on';
    options.Display='off';
    options.Diagnostics='off';
    options.TolX=1e-6;
    options.TolFun=1e-6;
    options.UseParallel = 1;
    options.MaxFunEvals=30000;
    options.MaxIter=30000;
    % canonical-hrf
    % startingparameters = ones(1,d+k)';
    % d = size(B,2),k = fmri_spec.nconditions;
    h_ini =  B \ hrf_ref;
    xBF_ref.bf = hrf_ref;
    X_ref = my_hrf_conv(U, fmri_spec,xBF_ref);
    designmatrix_ref = [];
    for i = 1 : fmri_spec.nconditions
        designmatrix_ref = [designmatrix_ref, X_ref{i}];
    end
    T = size(y,1);
    trend_design = ones(T,1);
    designmatrix_ref = [designmatrix_ref,trend_design];
    para_ini = designmatrix_ref \ y;
    % startingparameters = ones(d+k,1);startingparameters(end+1) = mean(y);
    startingparameters = [h_ini;para_ini];
    % optimization
    ObjectFunction = @(parameters)objectfunction4hrf(parameters,y,XB,lambda,B);
    para = fmincon(ObjectFunction,startingparameters,A,b,[],[],[],[],[],options);
    hrf = para(1:d,1); % para for hrf basis
    activation = para(d+1:d+k,1); % activation of k conditions
    r = para(d+k+1:d+k+1,1); % para for drift regressors
%   % Residual deviation test
%   e = y - XB*(kron(activation,hrf)) - trend_design*r;
%   PACF = parcorr(e)
end
% % % ----------------------------------------------------------------% % %
% step 7: output
% Normalize and set sign so that the estimated HRF is 
% positively correlated with canonical HRF
if strcmp(mode,'GLM') == 1
    for i = 1:k
        beta1 = beta(d*(i-1)+1:d*i,1);
        HRF(:,i) = B * beta1;
        % set sign
        hrf_sign = sign(hrf_ref' * HRF(:,i)); 
        HRF(:,i) = HRF(:,i) / hrf_sign;
        % normalization
        norm = max(HRF(:,i));
        activation(i,1) = norm * hrf_sign ;
        hrf(:,i) = beta1 / norm * hrf_sign;
        HRF(:,i) = HRF(:,i) / norm;
    end
elseif strcmp(mode,'r1GLM') == 1
    % <B*h,h_{red}> > 0
    HRF = B * hrf;
    norm = max(abs(HRF)); % 
    hrf_sign = sign(hrf_ref'*HRF); % set sign
    activation = activation * norm * hrf_sign;
    hrf = hrf / norm * hrf_sign; % normalization
    HRF = B * hrf;
end
