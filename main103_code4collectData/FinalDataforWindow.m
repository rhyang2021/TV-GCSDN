%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% combine the result data at window level and save
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load data(bigdata:info & choice,TS of 3 rois)
clear;clc
load('/Users/yangruihan/Desktop/data&code/taskfMRI/phenotypeData/datafordeception.mat');
clear Luo Luo2 Regions i datalength ans subject_list
clear BA10 BigMotion con iq iqid inc strat rTPJ earnings
typeName = {'Incr','Cons','Strat'};
% % % discard subject in outliers
outlier = [43,75];
inds (outlier) = [];
roi(outlier) = [];
roiTS = roi;
bigdata(outlier) = [];
clear  outlier roi

% % % --------------------------------------------------------------- % % %
%% calculate activation
% % % set parameter
load('/Users/yangruihan/Desktop/data&code/taskfMRI/resultData/wintypes');
nRoi = 3;
nWin = 60;
nTypes = 3;
nDir = nchoosek(nRoi,2)*2;
nSub = length(inds);
roi = cell(nSub,1);
for i = 1 : nSub
    roi{i}(:,1) = roiTS{i}(:,1);
    roi{i}(:,2) = roiTS{i}(:,2);
    roi{i}(:,3) = roiTS{i}(:,3);
end
nTrial =nWin;
IndSeq = cell(nSub,1);
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
    end
end
perchange  = cell(nSub,1);
activation = cell(nTypes,1);
for subj = 1 : nSub
    perchange{subj} = roi{subj};
    for i =1:nTypes
        for winNum = 1:size(Wintypes{subj,i},1)
            taskindex = zeros(1, size(roi{subj},1));
            winIndx = Wintypes{subj,i}(winNum,:);
            idx = winIndx(1):winIndx(2);
            for j = idx+1
                taskindex(IndSeq{subj}(j-1,2)+1:IndSeq{subj}(j,1)-1) = 1;
                taskindex(IndSeq{subj}(j,1)+1:IndSeq{subj}(j,2)) = 2;
                vols = (IndSeq{subj}(j,1)+1):IndSeq{subj}(j,2);
                for s = 1 : nRoi
                    perchange{subj}(vols,s)= roi{subj}(vols,s)...
                                          /roi{subj}(IndSeq{subj}(j,1),s);
                end
            end
            mtask = median(perchange{subj}(taskindex==2,:));
            activation{i,1} = [activation{i,1};subj,winNum,mtask];
        end
    end
end
clear j s subj v vols roi idx i perchange
clear  taskindex thinkingtime roiTS mtask
% save('.../resultData/activation','activation')
% % % --------------------------------------------------------------- % % %
%% gender age SES
[num,~] = xlsread('/Users/yangruihan/Desktop/data&code/taskfMRI/phenotypeData/phenotypeNew.xlsx');
num([43,75],:) = []; % filter out subjcet[43,75]
combCov = cell(3,1);
for subj = 1:nSub
    for stypes = 1:3
        for winNum = 1:size(Wintypes{subj,stypes},1)
            combCov{stypes,1} = [combCov{stypes,1};[subj,winNum,num(subj,4:6)]];
        end
    end
end
% % % --------------------------------------------------------------- % % %
%% IF: 59*6*74(outlier[43,75],6 directions,outlier first trail)
load('/Users/yangruihan/Desktop/data&code/taskfMRI/resultData/myResult_wid4_RegressHeadMotion_3HRF_noctrlSuddenMove_PatternSearch_initial.mat')
nWin = 59;
timeCauREbekkSig_tvTotal = nan(nWin,nDir,nSub);
for stypes = 1 : 3
    tempind = find(inds==stypes);
    for subindex = 1 :sum(inds==stypes)
        timeCauREbekkSig_tvTotal(:,:,tempind(subindex)) = ...
            timeCauREbekkSig_Sub{stypes}(:, :, subindex);
    end
end
IF = timeCauREbekkSig_tvTotal;
clear timeCauREbekk_tvSub timeCauREbekkSig_tvTotal
clear timeCauREbekkSig_Sub  timeCauREbekkSig_tvSub
% save('.../resultData/IF','IF')
% % % --------------------------------------------------------------- % % %
%% combine data
myResultAll = cell(3,1);
for subj = 1:nSub
    for stypes = 1:3
        for winNum = 1:size(Wintypes{subj,stypes},1)
            winIndx = Wintypes{subj,stypes}(winNum,:);
            % calculate IF
            if winIndx(1)~=winIndx(2)
            groupIF = mean(IF(winIndx(1):winIndx(2),:,subj));
            else
                groupIF = IF(winIndx(1):winIndx(2),:,subj);
            end
            % calculate slope and R^2
            tempx = bigdata{1,subj}.info(winIndx(1):winIndx(2),1);
            tempy = bigdata{1,subj}.choice(winIndx(1):winIndx(2),1);
            [beta,~,~,~,stats] = regress(tempy,[ones(length(tempx),1),tempx]);
            if isnan(stats(1))||isinf(stats(1))
                stats(1) = 0;
            end
            myResultAll{stypes,1} = [myResultAll{stypes,1};...
                                    [subj,winIndx,groupIF,beta(2),stats(1)]];
        end     
    end
end
clear tempx tempy beta stats winIndx winNum p r groupIF
clear subj typeName tempind subindex stable_tvSub result DBI1 statsTVwindow
FinalDataAll = [];
for stypes = 1:3
    combCov{stypes,1} = combCov{stypes,1}(:,3:5);
    activation{stypes,1} = activation{stypes,1}(:,3:5);
    FinalDataAll = [FinalDataAll;ones(size(myResultAll{stypes,1},1),1)*stypes,...
                    myResultAll{stypes,1},combCov{stypes,1},activation{stypes,1}];
end

names={'GroupID','SubID','Window begin','Window end','IF1',...
        'IF2','IF3','IF4','IF5','IF6','slope','R^2','Gender','Age',...
        'SES','activation1','activation2','activation3'};
save('/Users/yangruihan/Desktop/data&code/taskfMRI/resultData/finalData_windowLevel','FinalDataAll','names');
% clear name names
disp('The end ... ...')
