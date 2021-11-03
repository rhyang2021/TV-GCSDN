function [r_value,p_value,slope_value,R_squareRobust] = fun4Observations(wid,bigdata)
%% step 1:
%  calculate slope, R^2, spearman correlation coefficient, and p value at each 
%  sliding window (window length = 7).
r_value=zeros(60,76);
p_value=zeros(60,76);
slope_value = zeros(60,76);
R_squareRobust = zeros(60,76);
for subject = 1:76
    for i = 1:60
        if i > wid && i < 61-wid
            x = bigdata{subject}.info(i-wid:i+wid,:);
            y = bigdata{subject}.choice(i-wid:i+wid,:);
            betaRobust = robustfit(x,y);
            [r,p] = corr(x,y,  'type' ,'Spearman');
            r_value(i,subject) = r;
            p_value(i,subject) = p;
            slope_value(i,subject) = betaRobust(2);
        elseif i <= wid
            x = bigdata{subject}.info(i:i+5,:);
            y = bigdata{subject}.choice(i:i+5,:);
            [r,p] = corr(x,y,  'type' ,'Spearman');
            betaRobust = robustfit(x,y);
            r_value(i,subject) = r;
            p_value(i,subject) = p;
            slope_value(i,subject) = betaRobust(2);
        elseif i >= 61-wid
            x = bigdata{subject}.info(i-5:i,:);
            y = bigdata{subject}.choice(i-5:i,:);
            [r,p] = corr(x,y,  'type' ,'Spearman');
            betaRobust = robustfit(x,y);
            r_value(i,subject) = r;
            p_value(i,subject) = p;
            slope_value(i,subject) = betaRobust(2);
        end
        
        if isinf(r_value(i,subject))
            r_value(i,subject) = 0;
        elseif isnan(r_value(i,subject))
            r_value(i,subject) = 0;
        end
        if isinf(p_value(i,subject))
            p_value(i,subject) = 1;
        elseif isnan(p_value(i,subject))
            p_value(i,subject) = 1;
        end
        if isinf(slope_value(i,subject))
            slope_value(i,subject) = 0;
        elseif isnan(slope_value(i,subject))
            slope_value(i,subject) = 0;
        end
    end
end