%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Estimate HRF of each person from BOLD signal using 3-HRF basis
% NOTE that the dt needs to be matched with the trail onset, otherwise the
% discreted convolution would be incorrect
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;clear;
disp('Step 1: Load data and parameter setting');
RandStream('mt19937ar','seed',1000);
% load data
load('datafordeception.mat');
clear Luo Luo2  Regions i datalength ans subject_list

% % % ----------------------------------------------------------------% % %
% discard subject in outliers
clear con inc strat
outlier = [43,75];
bigdata(outlier) = [];
inds (outlier) = [];
BigMotion(outlier) = [];
roi(outlier) = [];
roiTS = roi;

clear idx outlier roi
idInc   = find(inds==1);    % inds is label
idCon   = find(inds==2);
idStrat = find(inds==3);

% % % ----------------------------------------------------------------% % %
% building basis function and parameter setting
nSub = length(roiTS);
datalength = nan(nSub,1);
roi = cell(nSub,1);

% 3 rois
for i = 1 : nSub
    roi{i}(:,1) = roiTS{i}(:,1);
    roi{i}(:,2) = roiTS{i}(:,2);
    roi{i}(:,3) = roiTS{i}(:,3);
    datalength(i) = size(roiTS{i},1);
end
nroi = size(roi{1},2);
nTrial = 60;
trail = reshape(1:nTrial,nTrial/60,60)';   %%% [1:20;21:40;41:60]
nWin = size(trail,1);
combination = nchoosek(1:nroi,2);
nPair = size(combination,1);
typename = {'Increamentalists', 'Conservatives', 'Strategists'};
nType = length(typename);   % 3 type of group subjects

% Head Motion
tmove = cell(nSub,1);
for subj = 1 : nSub
    temp = [BigMotion(subj).motion(1,:); BigMotion(subj).motion];
    temp = zscore(temp); % rotation may be scaled differently against location
    tmove{subj} = temp(1:end-1,:);
end
roi_pre = roi;

% onset: event train of 3 conditions
for i = 1:nSub
    onset{i,1}.sot{1} = [];
    onset{i,1}.sot{2} = [];
    onset{i,1}.sot{3} = [];
    for j = 1:nTrial
        if bigdata{i}.Timing(1).time(j) > floor(bigdata{i}.Timing(1).time(j))
            IndSeq{i}(j,1) = floor(bigdata{i}.Timing(1).time(j))+1;
        else
            IndSeq{i}(j,1) = bigdata{i}.Timing(1).time(j);  % in TRs
        end
        IndSeq{i}(j,2) = floor(bigdata{i}.Timing(2).time(j));
        thinkingtime(i,j) = IndSeq{i}(j,2) - IndSeq{i}(j,1)+1;
        onset{i,1}.sot{1} = [onset{i,1}.sot{1};bigdata{i}.Timing(1).time(j)]; % onset
        onset{i,1}.sot{2} = [onset{i,1}.sot{2};bigdata{i}.Timing(2).time(j)]; % choice
        onset{i,1}.sot{3} = [onset{i,1}.sot{3};(round(bigdata{i}.Timing(1).time(j))+1:...
                            round(bigdata{i}.Timing(2).time(j))-1)']; % thinking
    end
end
fmri_data = roi;
xBF.dt = 0.0625;   %  -time bin length {seconds}(16HZ)
% '3-HRF' -description of basis functions specified
xBF.name ='hrf (with time and dispersion derivatives)'; 
xBF = spm_get_bf(xBF);
fmri_spec.upsampling_factor = 32; % TR/dt(32 seconds)
fmri_spec.timing.units = 'scans';
fmri_spec.timing.RT = 2; % in seconds(2HZ)
fmri_spec.timing.fmri_t = 37; % see slicing timing(TR = 0.0625)
fmri_spec.timing.fmri_t0 = 19;
fmri_spec.onset = onset;
fmri_spec.datalength = datalength;
fmri_spec.nconditions = 3;
% 3 conditions
fmri_spec.U(1).dur = 0; fmri_spec.U(1).name = 'value';
fmri_spec.U(2).dur = 0; fmri_spec.U(2).name = 'choice';
fmri_spec.U(3).dur = 0; fmri_spec.U(3).name = 'thinking';
% motioin
fmri_spec.motion = tmove;
% method to calculate hrf
mode = 'GLM';
clear IndSeq inds iq iqid j i idCon idInc idStrat nPair earnings bigdata
clear datalength roi roi_pre temp BigMotion combination  BA10 rTPJ

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('step 2: Calculate hrf of each subj and each region and compare');
% Calculate hrf
for rois = 1:nroi
    parfor subj = 1 : nSub
        %hrfresult{subj,rois} = zeros(size(xBF.bf,1),3)
        hrfresult{subj,rois} = my_hrf(fmri_spec, subj,rois,xBF, fmri_data,mode);
    end
end

hrfAll = zeros(size(xBF.bf,1),3,74,3); % HRF for each person ,roi, condition
peakAll = zeros(nSub,nroi,3); % value from onset to peak value of HRF
for roi = 1:nroi
    for subj = 1:nSub
        for condition = 1:3
            hrfAll(:,subj,roi,condition) = hrfresult{subj,roi}(:,condition);
            peakAll(subj,roi,condition) = findpeak(hrfresult{subj,roi}(:,condition));
        end
    end
end

% % % ----------------------------------------------------------------% % %
% % % Calculate mean value of hrf for each roi and condition
for roi = 1:nroi
    for condition = 1:3
        meanRoi{condition,roi} = mean(hrfAll(:,:,roi,condition),2);
        stdRoi{condition,roi} = std(hrfAll(:,:,roi,condition),0,2);
    end
end
% save('.../resultData/meanHRF4roisandconditions','meanRoi','stdRoi');
peakAll = peakAll*xBF.dt; % 1 step = 0.0625s

% % % ----------------------------------------------------------------% % %
% % % paired t-test(BA10 && rDLPFC, rDLPFC && rTPJ, BA10 && rTPJ)
combination = [1,2;2,3;3,1];
H_All = zeros(3,nroi);
P_All = zeros(3,nroi);
for i = 1:3 % 3 conditions
    for j = 1:nroi
        [H_All(i,j),P_All(i,j)] = ttest(peakAll(:,combination(j,1),i)...
            -peakAll(:,combination(j,2),i),0,'Tail','both');
    end
end
% save('.../resultData/meanPeakvalue','peakAll');
clear combination  trail hrfAll nTrail nWin typename onset
disp(' ok ... ...');