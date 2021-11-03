function [index] = findpeak(timeseries)
len = size(timeseries,1);
% types = size(timesries,2);
platformlen = 10;
peaks = [];
for i = 1:platformlen
    platform = timeseries(1:i+platformlen,:);
    if timeseries(i,:)>=max(platform)
        peaks = [peaks,i];
    end
end
for i = platformlen+1:len-platformlen
    platform = timeseries(i-platformlen:i+platformlen,:);
    if timeseries(i,:)>=max(platform)
        peaks = [peaks,i];
    end
end
for i = len-platformlen+1:len
    platform = timeseries(i-platformlen:end,:);
    if timeseries(i,:)>=max(platform)
        peaks = [peaks,i];
    end
end
[~,p]=max(timeseries(peaks));
index = peaks(p);

