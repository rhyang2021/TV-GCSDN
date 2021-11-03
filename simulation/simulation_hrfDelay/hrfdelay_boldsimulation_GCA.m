function [CauREbekk,CauREbekksig,CauREbekkv,adf,res]= hrfdelay_boldsimulation_GCA(para_hrf, para_lag, para_A, para_B, para_noise)
% Instuction:
%   If region A causes activity changes in region B and region B has a 
%   faster hemodynamic response than region A, a Granger causality analysis
%   might indicate a net influence going from B to A rather than the true 
%   underlying causality from A to B. Here we simulate BOLD signal with SDN
%   and calculate GC using AR-bekk algorithm to show the causality is robust
%   to HRF delays between regions.
% % % ----------------------------------------------------------------% % %
disp('Step 2: Simulation BOLD signal with SDN');
sig_A_final = zeros(150,length(para_hrf),length(para_lag));
sig_B_final = zeros(150,length(para_hrf),length(para_lag));
for ihrf  = 1:length(para_hrf)
    for ilag = 1:length(para_lag)
        [sig_A_final(:,ihrf,ilag), sig_B_final(:,ihrf,ilag)] = ...
         simulation_ARbekk(para_hrf(ihrf),para_lag(ilag),para_A,para_B,para_noise);
    end
end
% plot(sig_A_final(:,1,1,1,1));
% hold on
% plot(sig_B_final(:,1,1,1,1),'r');

% % % ----------------------------------------------------------------% % %
disp('Step 3: Calculate granger causality using AR-bekk algorithm');
window = 1:150; % index of each observed repeat time series
wid = 1; % sum of window
combination = [1,2]; % calculate GC of two direcions
Nl= [1,150];  % index of each observed repeat time series
Nr = 1; % repeat times
k = 2; kx = 1; ky = 1; indexX = 1; indexY = 2;
ar_order = 1; % model order in AR
bekk_order = 1; % model order in SDN
sr = 0.5;
fd.EDFreq = sr/2; fd.STFreq = 0;
fd.NFFT = 256; fd.fs = sr;
for ihrf = 1:length(para_hrf)
    for ilag = 1:length(para_lag)
        data = [sig_A_final(:,ihrf,ilag), sig_B_final(:,ihrf,ilag)];
        % adftest
        [H_A,p_A] = adftest(sig_A_final(:,ihrf,ilag));
        [H_B,p_B] = adftest(sig_B_final(:,ihrf,ilag));
        adf(:,:,ihrf,ilag) = [H_A,p_A;H_B,p_B];
        % calculate GC
        for  i= 1 : size(combination,1)
            disp([num2str(wid),num2str(i)])
            input_data.timeseriesdata = data(:,combination(i,:));
            input_data.Nl = Nl; % [1,wlen];
            input_data.Nr = Nr; % 1;
            outputarmabekk = mv_grangerarmabekk4RepeatTimeVary(input_data,...
                            window, wid, ar_order, bekk_order, indexX, indexY, fd);
            CauREbekk(wid, 2*i-1, ihrf, ilag) = outputarmabekk.granger(1); % X2Y
            CauREbekk(wid, 2*i, ihrf, ilag) = outputarmabekk.granger(2); % Y2X
            CauREbekksig(wid, 2*i-1, ihrf, ilag) = outputarmabekk.granger(3); % X2Y
            CauREbekksig(wid, 2*i, ihrf, ilag) = outputarmabekk.granger(4); % Y2X
            CauREbekkv(wid, 2*i-1, ihrf, ilag) = outputarmabekk.granger(5); % X2Y
            CauREbekkv(wid, 2*i, ihrf, ilag) = outputarmabekk.granger(6); % Y2X
            para_reshape = reshapeparasXY(outputarmabekk.parameters,1,1,2,1,1);
        end
        % residuals
        [DW1,DW2,H1,p1,H2,p2] = Res4ARbekk(para_reshape,data);
        res(:,ihrf,ilag) = [DW1,DW2,H1,p1,H2,p2];
    end
end