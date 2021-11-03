function [Wintypes,combTVwindow] = fun4selectWinCalculateSlopeR_Square(path,mu1,bigdata)
%% step 3
sum_all = 0;sum_incr = 0;sum_cons = 0;sum_strat = 0;
combTVwindow{1,1} = [];combTVwindow{2,1} = [];combTVwindow{3,1} = [];
for subject = 1:76
    % % % ----------------------------------- % % %
    % Divide the hidden state identified by vierbi 
    % algorithm into incr(type 1), Cons(type 2), Strat(type3)
    label_new = path(:,subject);
    label_new(find(path(:,subject)==find(mu1(1,:)==max(mu1(1,:))))) = 1;
    label_new(find(path(:,subject)==find(mu1(1,:)==min(mu1(1,:))))) = 3;
    label_new(find(path(:,subject)==find(mu1(1,:)~=max(mu1(1,:)) ...
                                       & mu1(1,:)~=min(mu1(1,:))))) = 2;
    % % % ----------------------------------- % % %
    % window length no less than 8 indentifed
    window_initial = (1:59);
    index = 1;flag = 0;
    steps1 = 0;steps2 = 0;steps3 = 0;steps4 = 0;
    window1 = 0;window2 = 0;window3 = 0;window4 = 0;
    begin1 = 1;begin2 = 1;begin3 = 1;begin4 = 1;
    p_value_strat = [];p_value_incr = [];p_value_cons = [];
    r_value_incr = [];r_value_cons = [];r_value_strat = [];
    timewindow_incr = [];timewindow_cons=[];timewindow_strat = [];timewindow_none = [];
    while flag == 0
       if label_new(index,1) == 1 && ...
           bigdata{subject}.info(index)+2>= bigdata{subject}.choice(index)
            if steps1==0
                window1 = window1+1;
            end
            steps1 = steps1+1;
            timewindow_incr(window1,1) = window_initial(begin1);
            timewindow_incr(window1,2) = window_initial(begin1+steps1-1);
            begin2 = index+1;
            steps2 = 0;
            begin3 = index+1;
            steps3 = 0;
            begin4 = index +1;
            steps4 = 0;
        elseif  label_new(index,1) == 2 && ...
                bigdata{subject}.info(index)+2>= bigdata{subject}.choice(index)
            if steps2 == 0
                window2 = window2+1;
            end
            steps2=steps2+1;
            timewindow_cons(window2,1) = window_initial(begin2);
            timewindow_cons(window2,2) = window_initial(begin2+steps2-1);
            begin1 = index+1;
            steps1 = 0;
            begin3 = index+1;
            steps3 = 0;
            begin4 = index +1;
            steps4 = 0;
        elseif  label_new(index,1) == 3
            if steps3 == 0
                window3 = window3+1;
            end
            steps3 = steps3+1;
            timewindow_strat(window3,1) = window_initial(begin3);
            timewindow_strat(window3,2) = window_initial(begin3+steps3-1);
            begin1 = index+1;
            steps1 = 0;
            begin2=index+1;
            steps2=0;
            begin4 = index +1;
            steps4 = 0;
        else 
            if steps4 == 0
                window4 = window4+1;
            end
            steps4 = steps4+1;
            timewindow_none(window4,1) = window_initial(begin4);
            timewindow_none(window4,2) = window_initial(begin4+steps4-1);
            begin1 = index+1;
            steps1 = 0;
            begin2 = index+1;
            steps2 = 0;
            begin3 = begin3+1;
            steps3 = 0;
        end
        index=index+1;
        if index > size(label_new,1)
            flag =1;
        end
    end
    % % % ----------------------------------- % % %
    Wintypes{subject,1} = [];Wintypes{subject,2} = [];
    Wintypes{subject,3} = [];Wintypes{subject,4} = [];
    stableIncr = 0;stableCons = 0;stableStrat = 0;
    if size(timewindow_incr,1)~=0
        for i = 1:size(timewindow_incr,1)
             begin = timewindow_incr(i,1);
            ends = timewindow_incr(i,2);
            if   ends - begin + 1 >= 8
                stableIncr = stableIncr+1;
                sum_all=sum_all+1;
                sum_incr=sum_incr+1;
                Wintypes{subject,1} = [Wintypes{subject,1};[begin,ends]];
                combTVwindow{1,1} = [combTVwindow{1,1};[begin,ends,subject,stableIncr]];
            else
                Wintypes{subject,4} = [Wintypes{subject,4};[begin,ends]];
            end
        end
    end
    if size(timewindow_cons,1)~=0
        for i = 1:size(timewindow_cons,1)
            begin = timewindow_cons(i,1);
            ends = timewindow_cons(i,2);
            if   ends - begin + 1 >= 8
                stableCons = stableCons+1;
                sum_all = sum_all+1;
                sum_cons = sum_cons+1;
                Wintypes{subject,2} =[Wintypes{subject,2};[begin,ends]];
                combTVwindow{2,1} = [combTVwindow{2,1};[begin,ends,subject,stableCons]];
            else
                Wintypes{subject,4} = [Wintypes{subject,4};[begin,ends]];
            end
        end
    end
    if size(timewindow_strat,1)~=0
        for i = 1:size(timewindow_strat,1)
            begin = timewindow_strat(i,1);
            ends = timewindow_strat(i,2);
            if   ends - begin + 1 >= 8
                stableStrat = stableStrat+1;
                sum_all=sum_all+1;
                sum_strat=sum_strat+1;
                Wintypes{subject,3} =[Wintypes{subject,3};[begin,ends]];
                combTVwindow{3,1} = [combTVwindow{3,1};
                    [begin,ends,subject,stableStrat]];
            else
                Wintypes{subject,4} = [Wintypes{subject,4};[begin,ends]];
            end
        end
    end
    if size(timewindow_none,1)~=0
        for i = 1:size(timewindow_none,1)
            begin = timewindow_none(i,1);
            ends = timewindow_none(i,2);
            sum_all = sum_all+1;
            Wintypes{subject,4} = [Wintypes{subject,4};[begin,ends]];
        end
    end
end