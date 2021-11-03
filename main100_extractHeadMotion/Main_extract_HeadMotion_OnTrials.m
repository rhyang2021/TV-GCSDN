%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%              Head motion correlation               %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Load data
clear;close all;clc;
disp('Step 1: Load data and parameter setting');
RandStream('mt19937ar','seed',1000);
load('../phenotypeData/datafordeception.mat');
clear Luo Luo2  Regions i datalength ans subject_list
clear rTPJ BA10 earnings iqid roi roinames
clear con inc strat

%%% % % % % % % % % % % % % % % % % discard subject in outliers
outlier = [43,75];
BigMotion(outlier) = [];
bigdata(outlier) = [];

clear idx outlier roi iq inds 

% % % % % % % % % % % % % % % % % % % % % extract event onset (in IndSeq)
nSub = length(BigMotion);
nTrial = 60;
IndSeq = cell(nSub,1);
for subj = 1:nSub
for j = 1 : nTrial
    if bigdata{subj}.Timing(1).time(j) > floor(bigdata{subj}.Timing(1).time(j))
        IndSeq{subj}(j,1) = floor(bigdata{subj}.Timing(1).time(j)) + 1;
    else
        IndSeq{subj}(j,1) = bigdata{subj}.Timing(1).time(j);  % in TRs
    end
    IndSeq{subj}(j,2) = floor(bigdata{subj}.Timing(2).time(j));
    onset{subj}.sot{1}(j,1) = bigdata{subj}.Timing(1).time(j); % in TRs
end
end
clear onset j bigdata 

% % % % % % % % % % % % % % % % % % % Extract Head motion at trials level


HM_displamnt = nan(nSub,60,2);
HM_frameWise = nan(nSub,60,2);
for subj = 1:nSub
    tmp = BigMotion(subj).motion;
    tmpDiff = [tmp(1,:);diff(tmp)];
    for j = 1:60
        idx = IndSeq{subj}(j,1):IndSeq{subj}(j,2);
        HM_displamnt(subj,j,1) = max(sqrt(sum(tmp(idx,1:3).^2,2)));
        HM_displamnt(subj,j,2) = max(sqrt(sum(tmp(idx,4:6).^2,2)))*180/3.14;
        HM_frameWise(subj,j,1) = max(sqrt(sum(tmpDiff(idx,1:3).^2,2)));
        HM_frameWise(subj,j,2) = max(sqrt(sum(tmpDiff(idx,4:6).^2,2)))*180/3.14;
    end
end
HM_displamnt(:,1,:) = [];
HM_frameWise(:,1,:) = [];

clear  subj i j k  BigMotion
name = {'Transition','Rotation'};
% save('../resultData/HeadMotion','HM_displamnt','HM_frameWise','name');
% save('./HeadMotion','HM_displamnt','HM_frameWise','name');
disp('ok ... ...')
