%% ¼ÆËãdiff-ratioÏÔÖø´ÎÊý
load('resultRepeat100_HRFdelay20to140_Neuraldelay6to7.mat')
nRun = 100;
para_lag = 40:20:140;
para_hrf = 6:0.1:7;
countXY = zeros(3,length(para_hrf),length(para_lag));
countYX = zeros(3,length(para_hrf),length(para_lag));
for ihrf = 1:length(para_hrf)
    for ilag = 1:length(para_lag)
        for k = 1:nRun
            if ~isempty(result{1,1}{k,1})
                c = 1/2*(result{1,1}{k,1}.CauREbekk(1,1,ihrf,ilag)...
                    -result{1,1}{k,1}.CauREbekk(1,2,ihrf,ilag));
                if c > 4.61 % correct
                    countXY(3,ihrf,ilag) = countXY(3,ihrf,ilag)+1;
                elseif c < -4.61 % inverted
                    countXY(1,ihrf,ilag) = countXY(1,ihrf,ilag)+1;
                else % none-significant
                    countXY(2,ihrf,ilag) = countXY(2,ihrf,ilag)+1;
                end
            end
            if ~isempty(result{2,1}{k,1})
                c = 1/2*(result{2,1}{k,1}.CauREbekk(1,2,ihrf,ilag)...
                    -result{2,1}{k,1}.CauREbekk(1,1,ihrf,ilag));
                if c > 4.61 % correct
                    countYX(1,ihrf,ilag) = countYX(1,ihrf,ilag)+1;
                elseif c < -4.61 % inverted
                    countYX(3,ihrf,ilag) = countYX(3,ihrf,ilag)+1;
                else % none-significant
                    countYX(2,ihrf,ilag) = countYX(2,ihrf,ilag)+1;
                end
            end
        end
    end
end
%% bar plot
para_lag = [40,60;80,100;120,140];
fs = 22;
figure
for idx = 1:size(para_lag,1)
    for  idy = 1:size(para_lag,2)
        % X-->Y
        subplot(3,4,(idx-1)*4+idy)
        i = (idx-1)*2+idy;
        b=bar(countXY(:,:,i)','stacked','LineWidth',0.5,'LineStyle','-');
        b(1).BaseLine.LineStyle = 'None';
        set(b(1),'facecolor','r');
        set(b(2),'facecolor','b');
        set(b(3),'facecolor','g');
        for  p = 1:11
            if countXY(3,p,i)>=30 && countXY(3,p,i)<100
                text(p,100-countXY(3,p,i)+1,num2str(countXY(3,p,i)),...
                    'VerticalAlignment','bottom','HorizontalAlignment',...
                    'center','FontSize',fs-5,'FontName','Arial');
            elseif countXY(3,p,i)<30 && countXY(3,p,i)>1
                text(p,90-countXY(3,p,i),num2str(countXY(3,p,i)),...
                    'VerticalAlignment','bottom','HorizontalAlignment',...
                    'center','color','w','FontSize',fs-5,'FontName','Arial');
            end
            hold on
            if countXY(1,p,i)>1 && countXY(1,p,i)<100
                text(p,countXY(1,p,i)+0.5,num2str(countXY(1,p,i)),...
                    'VerticalAlignment','bottom','HorizontalAlignment',...
                    'center','color','w','FontSize',fs-5,'FontName','Arial');
            end
        end
        
        if idx ~= 3
            t1 = 0:0:0;
            set(gca,'box','on','ticklength',[0 0],'xtick',t1,'linewidth',1,...
                'fontsize',fs,'fontname','arial');
        else
            set(gca,'box','on','ticklength',[0 0],'Xtick',1:11,'xticklabel',...
                para_hrf,'Linewidth',1,'fontsize',fs-3,'fontname','arial');
        end
        if idy ~= 1
            t1 = 0:0:0;
            set(gca,'box','on','ticklength',[0 0],'ytick',t1,'linewidth',1,...
                'fontsize',fs,'fontname','arial');
        else
            set(gca,'box','on','ticklength',[0 0],'Ytick',0:20:100,'xticklabel',...
                para_hrf,'Linewidth',1,'fontsize',fs-3,'fontname','arial');
        end
        set(gca, 'XLim',[0.6 11.4]);
        set(gca, 'YLim',[0 100]);
        title(['lag = ',num2str(para_lag(i))],'fontsize',fs-3,...
            'fontname','arial','fontweight','normal')
    end
end
for idx = 1:size(para_lag,1)
    for  idy = 1:size(para_lag,2)
        subplot(3,4,(idx-1)*4+idy+2)
        i = (idx-1)*2+idy;
        b=bar(countYX(:,:,i)','stacked','LineWidth',0.5,'LineStyle','-');
        set(b(1),'facecolor','r');
        set(b(2),'facecolor','b');
        set(b(3),'facecolor','g');
        for  p = 1:11
            if countYX(3,p,i)>1 && countYX(3,p,i)<100
                text(p,96-countYX(3,p,i)+1,num2str(countYX(3,p,i)),...
                    'VerticalAlignment','bottom','HorizontalAlignment',...
                    'center','FontSize',fs-3,'FontName','Arial');
            end
            hold on
            if countYX(1,p,i)>1 && countYX(1,p,i)<70
                text(p,countYX(1,p,i)+1,num2str(countYX(1,p,i)),...
                    'VerticalAlignment','bottom','HorizontalAlignment',...
                    'center','color','w','FontSize',fs-6,'FontName','Arial');
            elseif countYX(1,p,i) >= 70 && countYX(1,p,i)<100
                text(p,countYX(1,p,i)-12,num2str(countYX(1,p,i)),...
                    'VerticalAlignment','bottom','HorizontalAlignment',...
                    'center','FontSize',fs-3,'FontName','Arial');
            end
        end
        t1 = 0:0:0;
        set(gca,'box','on','ytick',t1,'fontsize',fs,'fontname',...
            'arial','linewidth',1);
        if idx ~= 3
            t1 = 0:0:0;
            set(gca,'box','on','ticklength',[0 0],'xtick',t1,'linewidth',1,...
                'fontsize',fs,'fontname','arial');
        else
            set(gca,'box','on','ticklength',[0 0],'xtick',1:11,'xticklabel',...
                para_hrf,'Linewidth',1,'fontsize',fs,'fontname','arial');
        end
        set(gca, 'XLim',[0.6 11.4]);
        set(gca, 'YLim',[0 100]);
        title(['lag = ',num2str(para_lag(i))],'fontsize',fs-3,'fontname',...
            'arial','fontweight','normal')
        if idx == 1 && idy == 2
            hLegend = legend([b(1),b(2),b(3)], ...
                    'X->Y', 'none-significant', 'Y->X', ...
                    'Position',[0.58 0.94 0.51 0.06]);
            legend('boxoff','fontsize',fs)
            set(hLegend,...
            'Position',[0.59 0.94 0.5 0.07],...
            'NumColumns',2);
        end
        
    end
end
filename ='figure_hrf';
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf, 'PaperPosition', [0 0 80 35]);
print('-r600',gcf,'-djpeg',filename);
close all
disp('The end ... ...')