function output = mv_grangerarmabekk4Repeat(input_data, ar_order, bekk_order, indexX, indexY,fd)
% granger causality test between two groups of variables
% input:      input_data ---  input_data.timeseriesdata  -- timeseries data for AR-BEKK; data
%                                     for subjects have been concatenated 
%                                     together to form long time series data
%             input_data.Nr   --  number of repeat
%                    .Nl   -- index of each repeat
%             ar_order --- order of the AR model 
%             bekk_order --- order of the BEKK model
%             indexX --- the column id's of the first group in the data
%             indexY --- the column id's fo the second group in the data
% output:  armabekkX -- arma_bekk model for X by X
%             armabekkY -- arma_bekk model for Y by Y
%             armabekkXY -- joint arma_bekk model for X and Y
%             parameters -- given by the joint model
%             granger = [FX2Yv1,FY2Xv1, FX2Yv2,FY2Xv2]; statistics:
%             version1 is the comparison between variances
%             version2 is the comparison between auto correlations
%             version3 is the comparison between the variances of the error
%             and the corrected error
%% 'Please Note'
%% 'currently, we are specifying the model order without optimal selection
%% , since the model is very time consuming'
%% please note the maximum dimension is 10, the maximum orders p and q are
%% also 10s, and the maximum sample size is 25000 for mex functions

%% fitting models

data = input_data.timeseriesdata;
Nr = input_data.Nr;
Nl = input_data.Nl;

kx = size(indexX,2); ky = size(indexY,2);
k = size(data,2);

armabekkX = arma_bekk_mvgarch4Repeat(data(:,indexX), ar_order, bekk_order, Nr, Nl);
armabekkY = arma_bekk_mvgarch4Repeat(data(:,indexY), ar_order, bekk_order, Nr, Nl);
para_x=armabekkX.parameters;
para_y=armabekkY.parameters;
armabekkXY = arma_bekk_mvgarchXY4Repeat(data, ar_order, bekk_order, indexX, indexY, Nr, Nl,para_x,para_y);

%% calculating the statistics
[FX2Y,FY2X, p_x2y, p_y2x, FX2Yv, FY2Xv]  = arma_garch_grangercausality(armabekkXY, armabekkX, armabekkY, ar_order, bekk_order, k, kx, ky);

%% frequency domain
clear Fstats
% % get the ARmodel Coefs
para_armabekk = reshapeparasXY(armabekkXY.parameters, ar_order, bekk_order, k,kx,ky);
para_armabekkY = reshapeparas(armabekkY.parameters, ar_order, bekk_order, ky);
para_armabekkX = reshapeparas(armabekkX.parameters, ar_order, bekk_order, kx);
constx = para_armabekkX.C * para_armabekkX.C';
consty = para_armabekkY.C * para_armabekkY.C';

ARmodel.A(:,:,1) = eye(k);
for i = 1 : size(para_armabekk.A,3)
    ARmodel.A(:,:,i+1) = -para_armabekk.A(:,:,i)';   % for AR model in Matlab, the coefs need to be reversed
end
ARmodel.na = size(para_armabekk.A,3);

EDFreq = fd.EDFreq; STFreq = fd.STFreq;
NFFT = fd.NFFT; fs = fd.fs;
tmpd=(EDFreq-STFreq)/NFFT; %/fs*2*pi
stx=STFreq-tmpd;   %/fs*2*pi

cov_xy = cov(armabekkXY.errors);
cov_x = para_armabekk.constx;
cov_y = para_armabekk.consty;
cov_x1 = cov(armabekkX.errors);
cov_xx = (cov_x1 - constx);   
cov_y1 = cov(armabekkY.errors);
cov_yy = (cov_y1 - consty);



for i = 1 : NFFT 
    freq(i) = i * tmpd + stx;
    % Granger test on Frequency domain
    Fstats(i,:) =  frequencyforarbekk(ARmodel, kx, ky, freq(i), cov_xy, cov_x, cov_y, fs, cov_xx, cov_yy); 
end

%% output
output.armabekkX = armabekkX;
output.armabekkY = armabekkY;
output.armabekkXY = armabekkXY;
output.granger = [FX2Y,FY2X, p_x2y, p_y2x, FX2Yv, FY2Xv];
output.parameters = armabekkXY.parameters;
output.fgranger = [freq; Fstats'];