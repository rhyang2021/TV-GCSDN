function para = myAclassicmodel(t, id, u1, u2)
para = [0.1 0
        0   0.1*sqrt(2)];

if id == 1
    if t > 1000
        para(1,2) = 0;
    else
        para(1,2) = 0.4*(t-500)/500;
    end
    if t < 0
        para(2,1) = 0;
    else
        para(2,1) = 0.4*(1-t/500);
    end
end

% if id == 1
%     if t > 1000
%         para(1,2) = 0;
%     else
%         para(1,2) = 0.5*(t-500)/500;
%     end
% end