function [Final_Sig_A,  Final_Sig_B] = simulation_ARbekk(para_hrf,para_lag,para_a,para_b,para_noise)
% Instuction:
%   X and Y represent two brain areas. The time from onset to peak value 
%   of HRF in X(6s to 7s) is larger than that in Y(6s). Varying neuronal 
%   transmission delays from 40ms to 140ms,  we simulate different BOLD 
%   signals when potential causality of neural signals is X ¡ú Y and Y ¡ú X.
% Referece:
%   Schippers, M.B., Renken, R., Keysers, C., 2011.The effect of intra-and
%   inter-subject variability of hemodynamic responses on group level Granger
%   causality analyses. NeuroImage 57, 22?36.
%
% % % ----------------------------------------------------------------% % %
% generate two Granger-causal time series with SDN, X and Y
% potential causality: X ¡ú Y
corr = [0.9 0; para_a 0.9]; % para for AR
BX = [sqrt(0.01),0]; % noise described by signals
BY = [sqrt(para_b),sqrt(0.01)]; 
% % potential causality: Y ¡ú X
% corr = [0.9 para_a; 0 0.9];
% BY = [0,sqrt(0.01)];
% BX = [sqrt(0.01),sqrt(para_b)];
constx = 0.1; % noise-level of gassian noise
consty = 0.1;
timepoint = 300000;
l = para_lag; % neuronal delay
[Raw_Sig_A,  Raw_Sig_B] = generater_ARbekk(corr,BX,BY,constx,consty,timepoint,l);


% normalize signals to zero mean and unit variance.
Raw_Sig_A = Raw_Sig_A - mean(Raw_Sig_A);
Raw_Sig_B = Raw_Sig_B - mean(Raw_Sig_B);
Raw_Sig_A = Raw_Sig_A/std(Raw_Sig_A);
Raw_Sig_B = Raw_Sig_B/std(Raw_Sig_B);

% % % ----------------------------------------------------------------% % %
% generate hemodynamic response function
RT = 0.001;
P1 = [para_hrf 16 2 1 6 0 32];
P2 = [6 16 2 1 6 0 32];
[hrf1,~] = spm_hrf(RT,P1);
[hrf2,~] = spm_hrf(RT,P2);

% % % ----------------------------------------------------------------% % %
% convolve X and Y with hrfs
Coved_Sig_A = conv(Raw_Sig_A, hrf1);
Coved_Sig_B = conv(Raw_Sig_B, hrf2);
Coved_Sig_A = Coved_Sig_A(1:300000);
Coved_Sig_B = Coved_Sig_B(1:300000);
% normalize signals to zero mean and unit variance.
Coved_Sig_A = Coved_Sig_A - mean(Coved_Sig_A);
Coved_Sig_B = Coved_Sig_B - mean(Coved_Sig_B);
Coved_Sig_A = Coved_Sig_A/std(Coved_Sig_A);
Coved_Sig_B = Coved_Sig_B/std(Coved_Sig_B);

% % % ----------------------------------------------------------------% % %
% add gassian noise to represent physiological noise
noise1 = para_noise*randn(1,length(Coved_Sig_A));
Noise_Coved_Sig_A = Coved_Sig_A + noise1 ;
noise2 = para_noise*randn(1,length(Coved_Sig_B));
Noise_Coved_Sig_B = Coved_Sig_B + noise2 ;
% normalize signals to zero mean and unit variance.
Noise_Coved_Sig_A = Noise_Coved_Sig_A - mean(Noise_Coved_Sig_A);
Noise_Coved_Sig_B = Noise_Coved_Sig_B - mean(Noise_Coved_Sig_B);
Noise_Coved_Sig_A = Noise_Coved_Sig_A/std(Noise_Coved_Sig_A);
Noise_Coved_Sig_B = Noise_Coved_Sig_B/std(Noise_Coved_Sig_B);

% % % ----------------------------------------------------------------% % %
% downsampe X and Y to 150 steps(0.5HZ)
Down_Noise_Coved_Sig_A = downsample(Noise_Coved_Sig_A,2000);
Down_Noise_Coved_Sig_B = downsample(Noise_Coved_Sig_B,2000);
% normalize signals to zero mean and unit variance.
Down_Noise_Coved_Sig_A = Down_Noise_Coved_Sig_A - mean(Down_Noise_Coved_Sig_A);
Down_Noise_Coved_Sig_B = Down_Noise_Coved_Sig_B - mean(Down_Noise_Coved_Sig_B);
Down_Noise_Coved_Sig_A = Down_Noise_Coved_Sig_A/std(Down_Noise_Coved_Sig_A);
Down_Noise_Coved_Sig_B = Down_Noise_Coved_Sig_B/std(Down_Noise_Coved_Sig_B);

% % % ----------------------------------------------------------------% % %
% add gassian noise to represent acquisition noise
noise3 = para_noise * randn(1,length(Down_Noise_Coved_Sig_A));
Down_Noise_Coved_Sig_A = Down_Noise_Coved_Sig_A + noise3 ;
noise4 = para_noise * randn(1,length(Down_Noise_Coved_Sig_B));
Down_Noise_Coved_Sig_B = Down_Noise_Coved_Sig_B + noise4;
% normalize signals to zero mean and unit variance.
Final_Sig_A = Down_Noise_Coved_Sig_A - mean(Down_Noise_Coved_Sig_A);
Final_Sig_B = Down_Noise_Coved_Sig_B - mean(Down_Noise_Coved_Sig_B);
Final_Sig_A = Final_Sig_A/std(Final_Sig_A);
Final_Sig_B = Final_Sig_B/std(Final_Sig_B);
% plot(Final_Sig_A);  
% hold on
% plot(Final_Sig_B,'r');

