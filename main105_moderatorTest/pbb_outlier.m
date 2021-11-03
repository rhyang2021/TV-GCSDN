function [y,idx] = pbb_outlier(x)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here
        q = quantile(x, [0.25,0.75]);
        upper = q(2) + 1.5*(q(2)-q(1));
        lower = q(1) - 1.5*(q(2)-q(1));
        idx = (x>=lower)&(x<=upper);
        y = x(idx);     
end