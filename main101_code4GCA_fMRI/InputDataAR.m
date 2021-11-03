 
% input: data         -- post preprocessing data for all subjects, each cell
%                        for one subject, and in each cell there is a matrix with
%                        each column for one ROI
%        combination  -- the indexes for ROI's selected from data
%        IndSeq       -- each cell for one subject; in each cell, the index
%                        matrix with first column for trail onset and
%                        second for trail end
 
% output:  input_data.timeseriesdata  -- timeseries data for AR-BEKK; data
%                                     for subjects have been concatenated 
%                                     together to form long time series data
%          input_data.Nr   --  number of repeat
%                    .Nl   -- index of each repeat
%                 
function input_data = InputDataAR(data, combination, IndSeq)
con_data = []; % each column for one time series
indx_data = [];
Nr = 0;
for i = 1 : size(data, 2)
    for j = 1 : size(IndSeq{i},1)
        Nr = Nr + 1;
        indx_data = [indx_data; size(con_data,1)+1, size(con_data,1)+IndSeq{i}(j,2)-IndSeq{i}(j,1)+1];
        con_data = [con_data; data{i}(IndSeq{i}(j,1):IndSeq{i}(j,2), combination)];        
    end
end
input_data.timeseriesdata = con_data';
input_data.Nl = indx_data;    
input_data.Nr = Nr;

    
    

