%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  time-varying: this is the program for the paper tvGranger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load data
clear;clc;
disp('Step 1: Load data and parameter setting');
RandStream('mt19937ar','seed',654321);
load('.../phenotypeData/datafordeception.mat');
clear Luo Luo2  Regions i datalength ans subject_list
clear rTPJ BA10 earnings iqid
% iqid(length(iq)+1:end) = [];
% % % ----------------------------------------------------------------% % %
% % % discard subject in outliers
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
% % % parameter setting for globle variables
roinames = {'BA10','rDLPFC','rTPJ'};
nSub = length(roiTS);
datalength = nan(nSub,1);
roi = cell(nSub,1);
for i = 1 : nSub   % read BOLD signal of ROIs
    roi{i}(:,1) = roiTS{i}(:,1);
    roi{i}(:,2) = roiTS{i}(:,2);
    roi{i}(:,3) = roiTS{i}(:,3);
    datalength(i) = size(roiTS{i},1);
end
nroi = size(roi{1},2);
nTrial = 60;
trail = reshape(1:nTrial,nTrial/60,60)'; % [1:20;21:40;41:60]
nWin = size(trail,1);
combination = nchoosek(1:nroi,2);
nPair = size(combination,1);
typename = {'Increamentalists', 'Conservatives', 'Strategists'};
nType = length(typename);   % 3 type of group subjects

% % % ----------------------------------------------------------------% % %
% % % parameter setting for model
ar_order = 1;
bekk_order = 1;
indexX = 1;
indexY = 2;
sr = 0.5; % sampling frequency  (for spectral analysis only)
fd.EDFreq = sr/2; fd.STFreq = 0;
fd.NFFT = 256; fd.fs = sr;
combination = nchoosek(1:nroi,2);
disp('         have done ... ...')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Thinking time distribution
disp('Step 2: Thinking time distribution');
IndSeq = cell(nSub,1);
onset  = cell(nSub,1);
thinkingtime = nan(nSub,nTrial);
for i = 1 : nSub
    IndSeq{i,1} = zeros(nTrial,2);
    onset{i,1}.sot{1} = [];
    onset{i,1}.sot{2} = [];
    onset{i,1}.sot{3} = [];
    for j = 1 : nTrial
        if bigdata{i}.Timing(1).time(j) > floor(bigdata{i}.Timing(1).time(j))
            IndSeq{i}(j,1) = floor(bigdata{i}.Timing(1).time(j)) + 1;
        else
            IndSeq{i}(j,1) = bigdata{i}.Timing(1).time(j); % in TRs
        end
        IndSeq{i}(j,2) = floor(bigdata{i}.Timing(2).time(j));
        thinkingtime(i,j) = IndSeq{i}(j,2) - IndSeq{i}(j,1)+1;
        onset{i,1}.sot{1} = [onset{i,1}.sot{1};bigdata{i}.Timing(1).time(j)]; % onset
        onset{i,1}.sot{2} = [onset{i,1}.sot{2};bigdata{i}.Timing(2).time(j)]; % choice
        onset{i,1}.sot{3} = [onset{i,1}.sot{3};(round(bigdata{i}.Timing(1).time(j))+1:...
                            round(bigdata{i}.Timing(2).time(j))-1)']; % thinking
    end
end
% % % ----------------------------------------------------------------% % %
% % % Extract Head Motion
tmove = cell(nSub,1);
for subj = 1:nSub
    temp = [BigMotion(subj).motion(1,:); BigMotion(subj).motion];
    temp = zscore(temp); % rotation may be scaled differently against location
    tmove{subj} = temp(1:end-1,:);
end
disp('         have done ... ...')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  pipline for EPI    % preprocessing
disp('step 3: preprocessing of ROIs data')
% % establish residual process from BOLD signal by deconvoluting hrf
% % NOTE that the dt needs to be matched with the trail onset, otherwise the
% % discreted convolution would be incorrect
disp('       Building basis function and parameter setting for deconvolution')
load('....../resultData/meanHRF4roisandconditions.mat')
fmri_data = roi; % it can be file path for images, but need to revise some code
xBF = meanRoi;
fmri_spec.upsampling_factor = 32; % TR/dt
fmri_spec.timing.units = 'scans';
fmri_spec.timing.RT = 2; % in seconds
fmri_spec.timing.fmri_t = 37; % see slicing timing
fmri_spec.timing.fmri_t0 = 19;
fmri_spec.onset = onset; % in TRs
fmri_spec.datalength = datalength;
fmri_spec.nconditions = 3; % 3 condition
fmri_spec.U(1).dur = 0; fmri_spec.U(1).name = 'trail onset';
fmri_spec.U(2).dur = 0; fmri_spec.U(2).name = 'choice';
fmri_spec.U(3).dur = 0; fmri_spec.U(3).name = 'thinking';
fmri_spec.motion = tmove;
glmresult = cell(nSub,1);
delete(gcf)
for subj = 1 : nSub
    glmresult{subj} = my_deconvolution_new(fmri_spec, subj, xBF, fmri_data);
end
disp('       (1) done deconvolution!')

% % % ----------------------------------------------------------------% % %
%% clear predata
clear h_norm
predata = cell(nSub,1);
postdata = cell(nSub,1);
postSeq = cell(nSub,1);
for subj = 1 :nSub
    % considering the HRF delay
    predata{subj} = InputDataAR(glmresult(subj), 1:nroi, {IndSeq{subj}+1});    
    % drop the first trail 59 trails left
    [timeseries, postSeq{subj}] = preprocessing(glmresult{subj}, ...
                                  IndSeq{subj}, fmri_spec.motion{subj});
    % 59 trails
    postdata{subj} = InputDataAR({timeseries}, 1:nroi, {postSeq{subj}}); 
end
% hold on
% plot(postdata{1}.timeseriesdata(1,:),'--r')
% set(gcf,'position',[1400,200,1000,600]);
% plot()
disp('       (2) done zero mean')

% % % ----------------------------------------------------------------% % %
% % % group into types
clear postROI postInd preROI preInd
% increamentalist
for i = 1 : size(idInc,1)
    postROI{1}{i} = postdata{idInc(i)}.timeseriesdata';
    postInd{1}{i} = postdata{idInc(i)}.Nl;
    preROI{1}{i} = predata{idInc(i)}.timeseriesdata';
    preInd{1}{i} = predata{idInc(i)}.Nl;
end
% conservative
for i = 1 : size(idCon,1)
    postROI{2}{i} = postdata{idCon(i)}.timeseriesdata';
    postInd{2}{i} = postdata{idCon(i)}.Nl;
    preROI{2}{i} = predata{idCon(i)}.timeseriesdata';
    preInd{2}{i} = predata{idCon(i)}.Nl;
end
% strategist
for i = 1 : size(idStrat,1)
    postROI{3}{i} = postdata{idStrat(i)}.timeseriesdata';
    postInd{3}{i} = postdata{idStrat(i)}.Nl;
    preROI{3}{i} = predata{idStrat(i)}.timeseriesdata';
    preInd{3}{i} = predata{idStrat(i)}.Nl;
end
disp('       (3) done postROI')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% calculate the Granger causality for individual
disp('step 4: Calculate IF for each window of individual');
load('.../resultData/exclude.mat') % head motion
nTrial = size(postInd{1}{1,1},1);
trail = reshape(1:nTrial,1,nTrial)'; % [1:20;21:40;41:60]
nWin = size(trail,1);
timeCauREbekkSig = cell(3,nWin);
timeCauREbekkSig_tv = cell(3,nWin);
timeCauREbekk_tv = cell(3,nWin);
stable_tv = cell(3,nWin);
result_tv = cell(3,nWin);
for stypes =  1:nType % 3 groups
    label = find(inds == stypes);
    nSubGroup = sum(inds == stypes);
    for subindex = 1 : nSubGroup
        tic
        subID = label(subindex);
        exWin = exclude(subID,:);
        disp(['I am computing the group', num2str(stypes), ...
              ',  Subject:', num2str(subindex)])
        % GC with SDN
        for i = 1 :size(combination,1)
        clear input_data
        input_data.timeseriesdata = postROI{stypes}{subindex}(...
                                    :,combination(i,:));
        input_data.Nl = postInd{stypes}{subindex};
        input_data.Nr = size(input_data.Nl,1);
        input_data.exclude = exWin;
        parfor idTrail = 1:nWin
        outputarmabekk = mv_grangerarmabekk4RepeatTimeVary(input_data, ...
                         trail, idTrail, ar_order, bekk_order, indexX, indexY, fd);
        timeCauREbekkSig{stypes,idTrail}(2*i-1, subindex) = outputarmabekk.granger(1);
        timeCauREbekkSig{stypes,idTrail}(2*i, subindex) = outputarmabekk.granger(2);
        timeCauREbekkSig_tv{stypes,idTrail}(2*i-1, subindex) = outputarmabekk.granger(3);
        timeCauREbekkSig_tv{stypes,idTrail}(2*i, subindex) = outputarmabekk.granger(4);
        timeCauREbekk_tv{stypes,idTrail}(2*i-1, subindex) = outputarmabekk.granger(5);
        timeCauREbekk_tv{stypes,idTrail}(2*i, subindex) = outputarmabekk.granger(6);
        stable_tv{stypes,idTrail}(i, subindex) = stationary_constraint(...
                                                 outputarmabekk.parameters, 1, 1, 2, 1, 1);
        result_tv{stypes,idTrail}{subindex}(:,i) = outputarmabekk.parameters;
        end
        end
        toc
    end
end
%%
timeCauREbekkSig_Sub = cell(3,1);
timeCauREbekkSig_tvSub = cell(3,1);
timeCauREbekk_tvSub = cell(3,1);
stable_tvSub = cell(3,1);
result = cell(3,1);
for stypes =  1:nType   %%% 3 groups
    label = find(inds == stypes);
    nSubGroup = sum(inds == stypes);
    for subindex = 1 : nSubGroup
        for i = 1 :size(combination,1)
            for idTrail = 1:nWin
                timeCauREbekkSig_Sub{stypes}(idTrail,2*i-1,subindex) = ...
                    timeCauREbekkSig{stypes,idTrail}(2*i-1, subindex);
                timeCauREbekkSig_Sub{stypes}(idTrail,2*i,subindex) = ...
                    timeCauREbekkSig{stypes,idTrail}(2*i, subindex);
                timeCauREbekkSig_tvSub{stypes}(idTrail,2*i-1,subindex) = ...
                    timeCauREbekkSig_tv{stypes,idTrail}(2*i-1, subindex);
                timeCauREbekkSig_tvSub{stypes}(idTrail,2*i,subindex) = ...
                    timeCauREbekkSig_tv{stypes,idTrail}(2*i, subindex);
                timeCauREbekk_tvSub{stypes}(idTrail,2*i-1,subindex) = ...
                    timeCauREbekk_tv{stypes,idTrail}(2*i-1, subindex);
                timeCauREbekk_tvSub{stypes}(idTrail,2*i,subindex) = ...
                    timeCauREbekk_tv{stypes,idTrail}(2*i, subindex);
                stable_tvSub{stypes}(idTrail,i,subindex) = ...
                    stable_tv{stypes,idTrail}(i, subindex);
                result{stypes}{subindex,idTrail}(:,i) = ...
                    result_tv{stypes,idTrail}{subindex}(:,i);
            end
        end
    end
end
% save('...resultData/myResult_wid4_RegressHeadMotionRe_3HRF_noctrlSuddenMove_PatternSearch_initial',...
%     'result', 'stable_tvSub','timeCauREbekkSig_Sub','timeCauREbekk_tvSub','timeCauREbekkSig_tvSub');
disp('The End ... ...')
%exit