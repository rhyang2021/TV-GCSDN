clear;close all;clc;
load('../resultData/finalData_windowLevel')
label = {'BA10 \rightarrow rDLPFC', 'rDLPFC \rightarrow BA10',...
    'BA10 \rightarrow rTPJ', 'rTPJ \rightarrow BA10',...
    'rDLPFC \rightarrow rTPJ', 'rTPJ \rightarrow rDLPFC'};
mark = {'A','B','C','D','E','F'};
x = [0.005 0.35 0.67 0.005 0.35 0.67];
y = [0.935 0.935 0.935 0.43 0.43 0.43];
xx = [0.005 0.35 0.67 0.005 0.35 0.67];
yy = [0.935 0.935 0.935 0.43 0.43 0.43];
fs = 12;
ps=[0.1 0.61;
    0.42  0.61;
    0.74 0.61;
    0.1 0.105;
    0.42  0.105;
    0.74 0.105];
groupID = FinalDataAll(:,1);
phenoData = FinalDataAll(:,13:15);
active = FinalDataAll(:,16:18);
roiSeq = nchoosek(1:3,2);
% % % ------------------------------------------------------ % % %
% % % Group difference
figure
for kk = 1:6
    subplot(2,3,kk);
    IF = FinalDataAll(:,4+kk);
    roiNo = roiSeq(round(kk/2),:);
    covs = [phenoData,active(:,roiNo)]; % Age Gender SES activition
    tmpCovs = covs;
    tmpID = groupID;
    % regress covarians
    [~,~,r] = regress(IF,[ones(size(tmpCovs,1),1),tmpCovs]);
    IF = deleteoutliers(r,0.0025,1); % discard outliers by 3-sigma rule
    sum(isnan(IF(1:78)))-sum(isnan(r(1:78)))
    sum(isnan(IF(79:104)))-sum(isnan(r(79:104)))
    sum(isnan(IF(105:end)))-sum(isnan(r(105:end)))
    [p,~,stat] = anova1(IF,tmpID,'on');
    % [p,~,stat] = kruskalwallis(IF,tmpID,'off');
    boxplot(IF,tmpID);
    
    set(gca,'position',[ps(kk,1),ps(kk,2),0.23,0.3],...
        'xticklabel',{'Incr.','Cons.','Strat.'},...
        'fontsize',fs,'fontname','arial','linewidth',0.8,'box','off');
    title(['p = ',num2str(round(p*10000)/10000)],'fontsize',fs-2,...
        'fontweight','normal','fontname','arial');
    xlabel(label{kk},'fontsize',fs,'fontname','arial');
    
    if mod(kk,3)==1
        ylabel('Information flow (IF)','fontsize',fs,'fontname','arial');
    end
    annotation(gcf,'textbox',...
        [xx(kk)  yy(kk) 0.05 0.07],...
        'String',mark{kk},'LineStyle','none',...
        'FitBoxToText','off','fontsize',fs+1,...
        'fontweight','bold','fontname','arial');
    
end
% % % ------------------------------------------------------ % % %
% % % behavioral correlation
stype = 3; % Strategic window group
figure
for kk = 1:6
    subplot(2,3,kk)
    IF = FinalDataAll(:,4+kk);
    slope = FinalDataAll(:,11); % Slope
    % R_square = FinalDataAll(:,12); % R^2
    roiNo = roiSeq(round(kk/2),:);
    covs = [phenoData,active(:,roiNo)]; % Age Gender SES activation
    groupID = FinalDataAll(:,1);
    idx = groupID ==stype;
    tmpSlope = slope(idx);
    tmpIF = IF(idx);
    tmpCovs = covs(idx,:);
% % % % % % % % % % % % % discard outliers (one point at BA10 -> rTPJ)    
    [~,idx1] = pbb_outlier(tmpIF);
    idx2 = tmpIF>0;
    idx3 = idx1.*idx2;
    tmpIF = tmpIF(idx3==1,:);
    tmpSlope = tmpSlope(idx3==1,:);
    tmpCovs = tmpCovs(idx3==1,:);
     
% % % % % % % % % % % % %  discard max and min Slope
    [~,idx6] = max(tmpSlope);
    tmpIF(idx6,:) = [];
    tmpSlope(idx6,:) = [];
    tmpCovs(idx6,:) = [];  
    [~,idx6] = min(tmpSlope);
    tmpIF(idx6,:) = [];
    tmpSlope(idx6,:) = [];
    tmpCovs(idx6,:) = []; 

% % % % % % % % % % % % %  correlation
    [r,p] = corr(tmpSlope,tmpIF);
    disp([r,p])
    % % if consider the covarians
    idx4 = ~isnan(sum(tmpCovs,2));
    tmpCovs = tmpCovs(idx4==1,:);
    tmpIF = tmpIF(idx4==1,:);
    tmpSlope = tmpSlope(idx4==1,:);
    idx5 = ~isnan(sum(tmpSlope,2));
    tmpCovs = tmpCovs(idx5==1,:);
    tmpIF = tmpIF(idx5==1,:);
    tmpSlope = tmpSlope(idx5==1,:);
    [r2,p2] = partialcorr(tmpSlope,tmpIF,tmpCovs,'type','Pearson');
    disp([r2,p2])
    plot(tmpIF,tmpSlope,'o','markersize',3,'color','b');
    lsline
    set(gca,'position',[ps(kk,1),ps(kk,2),0.23,0.33],...
        'fontsize',fs,'fontname','arial');
    title(['p = ',num2str(round(p2*10000)/10000)],'fontsize',fs-2,...
        'fontweight','normal','fontname','arial');
    
    xlabel(['IF_{',label{kk},'}'],'fontsize',fs,'fontname','arial');
    
    if mod(kk,3)==1
        ylabel('Slope','fontsize',fs,'fontname','arial');
    end
    
    annotation(gcf,'textbox',...
        [xx(kk)  yy(kk) 0.05 0.07],...
        'String',mark{kk},'LineStyle','none',...
        'FitBoxToText','off','fontsize',fs+1,...
        'fontweight','bold','fontname','arial');  
end