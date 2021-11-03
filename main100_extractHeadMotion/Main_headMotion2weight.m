% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %  create weight on trial according Head motion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% % % Load data
clear;close all;clc;
load('../phenotypeData/datafordeception.mat');
clear Luo Luo2  Regions i datalength ans subject_list roi
clear BA10 inds iqid rTPJ roinames iq

% % % ---------------------------------------------% % %
% % % % discard subjects in outliers
clear con inc strat
outlier = [43,75];
bigdata(outlier) = [];
BigMotion(outlier) = [];
clear idx outlier roi
nSub = length(bigdata);
nTrial = 60;

% % % ---------------------------------------------% % %
% %%  Thinking time distribution
disp('Step 2: Thinking time distribution');
IndSeq = cell(nSub,1);
onset  = cell(nSub,1);
thinkingtime = nan(nSub,nTrial);
for i = 1 : nSub
    IndSeq{i,1} = zeros(nTrial,2);
    for j = 1 : nTrial
        if bigdata{i}.Timing(1).time(j) > floor(bigdata{i}.Timing(1).time(j))
            IndSeq{i}(j,1) = floor(bigdata{i}.Timing(1).time(j)) + 1;
        else
            IndSeq{i}(j,1) = bigdata{i}.Timing(1).time(j);  % in TRs
        end
        IndSeq{i}(j,2) = floor(bigdata{i}.Timing(2).time(j));
        thinkingtime(i,j) = IndSeq{i}(j,2) - IndSeq{i}(j,1)+1;
        onset{i}.sot{1}(j,1) = bigdata{i}.Timing(1).time(j); % in TRs
    end
end
clear thinkingtime onset

% % % -------------------------------% % %
% %% Extract Head Motion
tmove = cell(nSub,1);
for subj = 1 : nSub
    temp = [BigMotion(subj).motion(1,:); BigMotion(subj).motion];
    temp = zscore(temp); % rotation may be scaled differently against location
    tmove{subj} = temp(1:end-1,:);
end

% % % ---------------------------------------------% % %
newExclude = zeros(nSub,nTrial);
for subj = 1:nSub
    move = tmove{subj};
    for iTrail = 1 : size(IndSeq{subj},1)
        indexTrail = IndSeq{subj}(iTrail,1) : IndSeq{subj}(iTrail,2);
        tmpMove = [sqrt(sum(diff(move(indexTrail,1:3)).^2,2)),...
            sqrt(sum(diff(move(indexTrail,4:6)).^2,2))];
        newExclude(subj,iTrail) = max(tmpMove(:));
    end
end

% my_pcolor(newExclude>2);
exclude = newExclude;
% save('exclude','exclude');
% save('../main101_code4GCA_fMRI/exclude','exclude');
clear i j iTrail subj nTrial nSub
disp('The End ... ...')