% input: each column stands for one time series
function [postX,postSeq] = preprocessing(X, IndSeq, move)
% % % we need to drop the first trail 59 trails left
% % % contrast to rest
ttpostX = X;

% % drop the first trail
ttpostX(1:IndSeq(2,1)-1, :) = [];
postSeq = IndSeq(2:end,:)-IndSeq(2,1)+1;

% % zero mean at each trail
postX = ttpostX;
for iTrail = 1 : size(postSeq,1)
    temporalmean = mean(ttpostX(postSeq(iTrail,1) : postSeq(iTrail,2),:));
    for j = postSeq(iTrail,1) : postSeq(iTrail,2)
        postX(j,:) = ttpostX(j,:) - temporalmean;
    end
end    