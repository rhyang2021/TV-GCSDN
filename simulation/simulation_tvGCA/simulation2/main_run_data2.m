%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simulation 2
%  we simulate two time-varying time series X and Y with SDN, and Granger 
%  causality only exist in SDN. Granger causality strength of Y to X varys
%  from sqrt(0.4) to 0, and strength of X to Y varys from 0 to sqrt(0.4).
%  we calculate GC using Classical GC, GCSDN and time-varying GCSDN at
%  five windows and whole time series.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;close all;clc;
nRun = 100;
result= cell(nRun,1);
RandStream('mt19937ar','seed',654321);  % seed for random numbers
for run = 1:nRun
    disp(['run = ',num2str(run)]);
    ar_order = 1;   % model order in AR
    bekk_order = 1; % model order in SDN
    t = 1000;       % length of time series
    Nr = 1;         % repeat times
    Nl = [1,t];     % index of each observed repeat time series
    k = 2; kx = 1; ky = 1; indexX = 1; indexY = 2;
    
    %%   simulation:  multiple observation
    A = @(x,id)myA(x, id); % we use A' in simulation;
    CX = 1; % kx * kx
    CY = 1; % ky * ky
    constx = tril(CX) * tril(CX)';
    consty = tril(CY) * tril(CY)';
    BX = @(x,id)myBX(x, id);
    BY = @(x,id)myBY(x, id);
    
    data = zeros(Nr*t,k); Ht = zeros(k,k,Nr*t);
    for i = 1 : Nr
        [tdata, tHt] = arma_bekk_simulate_timevarying(t,k,kx,ky,...
                       A, constx, consty, BX, BY, ar_order,bekk_order);
        data(Nl(i,1):Nl(i,2), :) = tdata;
        Ht(:,:, Nl(i,1):Nl(i,2)) = tHt;
    end
    
    clear tdata
    clear tHt
    
    % % % ------------------------------------------------------------% % %
    % display the time series
    % Ylabel = {'X', 'Y'};
    % figure('name', 'AR model with ARCH error')
    % plotmultiplyTS(data(:, :), Ylabel, 2,1)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% calculate Granger causality by different models
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% basic settings for the model
    sr      =   0.5;        % sampling frequency  (for spectral analysis only)
    fd.EDFreq = sr/2; fd.STFreq = 0;
    fd.NFFT = 256; fd.fs = sr;
    clear timeCau;
    clear freqCau;
    clear freq;
    combination = [1,2];
    combinationAR = [1,2; 2,1];
    order = 1;
    ar_order = 1;
    bekk_order = 1;
    
    % % % ------------------------------------------------------------% % %
    %%    for whole time series
    %%    By AR
    for i = 1 : size(combinationAR,1)
        clear input_data
        input_data = data(:,combinationAR(i,:))'; % preparing the input data for algorithm
        % model estimation
        [CauREARall(i),VarErrARall{i}, EEout2all{i}, coeffARall{i}, CAuREARsigall(i)] = ...
            CauRepeat(input_data(2,:),input_data(1,:),order, Nr, Nl);
    end
    % CauREARall
    % CAuREARsigall
    result{run,1}.CauREARall = CauREARall;
    result{run,1}.CAuREARsigall =CAuREARsigall;
    result{run,1}.coeffARall =coeffARall;
    
    
    %%    By AR-bekk
    clear parall;
    for i = 1 : size(combination,1)
        % formating the input data for algorithm
        clear input_data
        input_data.timeseriesdata = data(:,combination(i,:));
        input_data.Nl = Nl;%[1,wlen];
        input_data.Nr = Nr;% 1;
        % model estimation
        outputarmabekk = mv_grangerarmabekk4Repeat(input_data, ...
                         ar_order, bekk_order, indexX, indexY, fd);
        CauREbekkall(2*i-1) = outputarmabekk.granger(1);
        CauREbekkall(2*i) = outputarmabekk.granger(2);
        CauREbekksigall(2*i-1) = outputarmabekk.granger(3);
        CauREbekksigall(2*i) = outputarmabekk.granger(4);
        CauREbekkvall(2*i-1) = outputarmabekk.granger(5);
        CauREbekkvall(2*i) = outputarmabekk.granger(6);
        parall{i}= outputarmabekk.parameters;
        stableall(i) = stationary_constraint(outputarmabekk.parameters, ...
                        ar_order, bekk_order, k, kx, ky);
    end
    % CauREbekkall
    % CauREbekksigall
    % CauREbekkvall
    result{run,1}.CauREbekkall = CauREbekkall;
    result{run,1}.CauREbekksigall =CauREbekksigall;
    result{run,1}.CauREbekkvall =CauREbekkvall;
    result{run,1}.stableall =  stableall;
    result{run,1}.parall = parall;
    
    
    % % % ------------------------------------------------------------% % %
    %%    sliding window
    % % % window = [1:200; 201:400; 401:600; 601:800; 801:1000];
    wlen =  200;
    nWin = t/wlen;
    window = reshape(1:t,wlen,nWin)';
    
    %% %  By classical Granger causality
    %% %  method: AR
    for wid = 1 : size(window,1)
        for i = 1 : size(combinationAR,1)
            clear input_data
            % preparing the input data for algorithm
            input_data = data(window(wid,:),combinationAR(i,:))';    
            % model estimation
            [CauREAR(wid, i),VarErrAR{wid, i}, EEout2{wid, i}, ...
            coeffAR{wid, i}, CauREARsig(wid,i)] = ...
            CauRepeat(input_data(2,:),input_data(1,:),order, 1, [1,wlen]);
        end
    end
    % CauREAR
    % CauREARsig
    result{run,1}.CauREAR = CauREAR;
    result{run,1}.CauREARsig = CauREARsig;
    result{run,1}.coeffAR =coeffAR; 
    
    %%    method: AR-bekk
    Nl = [1,200];
    clear parall;
    for wid = 1:size(window,1)
    for i = 1 : size(combination,1)
        % formating the input data for algorithm
        clear input_data
        input_data.timeseriesdata = data(window(wid,:),combination(i,:));
        input_data.Nl = Nl;%[1,wlen];
        input_data.Nr = Nr;% 1;
        % model estimation
        outputarmabekk = mv_grangerarmabekk4Repeat(input_data, ...
                         ar_order, bekk_order, indexX, indexY, fd);
        CauREbekkWin(wid,2*i-1) = outputarmabekk.granger(1);
        CauREbekkWin(wid,2*i) = outputarmabekk.granger(2);
        CauREbekksigWin(wid,2*i-1) = outputarmabekk.granger(3);
        CauREbekksigWin(wid,2*i) = outputarmabekk.granger(4);
        CauREbekkvWin(wid,2*i-1) = outputarmabekk.granger(5);
        CauREbekkvWin(wid,2*i) = outputarmabekk.granger(6);
        paraWin{i}= outputarmabekk.parameters;
        stableWin(i) = stationary_constraint(outputarmabekk.parameters, ...
                       ar_order, bekk_order, k, kx, ky);
    end
    end
    result{run,1}.CauREbekkWin = CauREbekkWin;
    result{run,1}.CauREbekksigWin =CauREbekksigWin;
    result{run,1}.CauREbekkvWin =CauREbekkvWin;
    result{run,1}.stableWin =  stableWin;
    result{run,1}.paraWin = paraWin;
    
    %%    By Granger causality with signal-dependent noise
    Nl = [1,1000];
    clear para;
    for wid = 1 : size(window,1)
        for  i= 1 : size(combination,1)
            disp([num2str(wid), num2str(i)])
            % formating the input data for algorithm
            clear input_data
            input_data.timeseriesdata = data(:,combination(i,:));
            input_data.Nl = Nl; % [1,wlen];
            input_data.Nr = Nr; % 1;
            % model estimation
            outputarmabekk = mv_grangerarmabekk4RepeatTimeVary(input_data,...
                            window, wid, ar_order, bekk_order, indexX, indexY, fd);
            CauREbekk(wid, 2*i-1) = outputarmabekk.granger(1);
            CauREbekk(wid, 2*i) = outputarmabekk.granger(2);
            CauREbekksig(wid, 2*i-1) = outputarmabekk.granger(3);
            CauREbekksig(wid, 2*i) = outputarmabekk.granger(4);
            CauREbekkv(wid, 2*i-1) = outputarmabekk.granger(5);
            CauREbekkv(wid, 2*i) = outputarmabekk.granger(6);
            para{wid,i} = outputarmabekk.parameters;
            stable(wid, i) = stationary_constraint(outputarmabekk.parameters, ...
                             ar_order, bekk_order, k, kx, ky);
        end
    end
    % CauREbekk
    % CauREbekksig
    % CauREbekkv
    result{run,1}.CauREbekk = CauREbekk;
    result{run,1}.CauREbekksig = CauREbekksig;
    result{run,1}.CauREbekkv =CauREbekkv;
    result{run,1}.stable = stable;
    result{run,1}.para = para;
end
% save('result_model2','result');
% exit