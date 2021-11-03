% filter out the surden movement effects by setting interpolation value to some
% signals corresponding to surden movement for each group. The constant
% factor 2 means we define the movement larger than 2 \sigma of
% movements as surden movement
function dataout = filtermovement(move, data)

% move = movement_data.timeseriesdata;
% data = input_data.timeseriesdata;
[mdim, t1] = size(move);
t2 = size(data,2);
mdata = mean(data,2);
if t1 ~= t2
    'error in data input. the lengths do not match'
end
% find std for each dimension
index_all = [];
for j = 1 : mdim
    clear index
    [~,index] = deleteoutliers(move(j,:),0.001);
    index_all = [index_all, index];
end
index_all = unique(index_all);

count = 0;
data2 = data;
for j = 1 : length(index_all)
    t = index_all(j);
    if t > 2 && t < t2-2
        % interpolation
        data2(:,t) = 2 * (data2(:,t+3) - data2(:,t-2)) /5 + data2(:,t-2);
        count = count + 1;
    elseif t < 3
        data2(:,t) = (t-5) * (data2(:,6) - data2(:,5)) + data2(:,5);
        count = count + 1;
    elseif t > t2-3
        data2(:,t) = 4 * data2(:,t-3) - 3 * data2(:,t-4);
        count = count + 1;
    else
        '??'
    end    
end
dataout = data2';
disp(['movement correction: ', num2str(count)])
