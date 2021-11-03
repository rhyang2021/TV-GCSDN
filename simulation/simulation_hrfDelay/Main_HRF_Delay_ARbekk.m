%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Simulate BOLD signal with SDN, and use AR-bekk algorithm to calculate 
% the granger causality. 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;clear;
disp('Step 1: parpool and parameter setting');
core = 8;
pop = parpool(core); 
pop.IdleTimeout = 36*1e10;
RandStream('mt19937ar','seed',654321);  % seed for random numbers
para_hrf = 6:0.1:7; % hrf delay from 0.1s to 1s
para_lag = 40:20:140; % neural delay from 40ms to 140ms
para_A = 0.5; % granger causality strength
para_B = 0.005; % noise-level of SDN
para_noise = 0.1; % noise-level of gassian white noise
nRun = 100; % repeat 100 times
parfor kRun =1:nRun
    disp(['run = ',num2str(kRun)]);
    tic
    [CauREbekk, CauREbekksig, CauREbekkv, adf, res]...
    = hrfdelay_boldsimulation_GCA(para_hrf, para_lag, para_A, para_B, para_noise);
    result{kRun,1}.CauREbekk = CauREbekk; % GC of X to Y and Y to X
    result{kRun,1}.CauREbekksig = CauREbekksig; % p value
    result{kRun,1}.CauREbekkv = CauREbekkv;
    result{kRun,1}.res = res; % residual
    result{kRun,1}.adf = adf; % adf test
    toc
end
delete(gcp('nocreate'));
% delay = 1;
% hrf = 1;
% ratio= [];
% pvalue = [];
% for k = 1 : 8
%     ratio(k,:) = result{k,1}.CauREbekk(1,:,hrf,delay);
%     pvalue(k,:) = result{k,1}.CauREbekksig(1,:,hrf,delay);
% end
% [mean(ratio),mean(pvalue)]