function [newA, newC, newB]  = initialparaforARBEKK(data, k, ar_order, bekk_order)
%% estimate the initial parameters by one dimensional model
% fit an one dimensional arma_garch model as the intial paramters for
% amra_bekk
newA = zeros(k, k, ar_order);
newC = zeros(k,k);
newB = zeros(k, k, bekk_order);

%% use ar model first
m0 = arx(iddata(data, [],1), ar_order * ones(k,k));
Err = pe(m0, data); % must discard the first ar_order errors
[newB, newC] = regresserror(Err, data, ar_order,bekk_order);
for i  = 1 : ar_order
    if k > 1
        for k1 = 1 : k
            for k2 = 1 : k
                newA(k1,k2,i) = -m0.a{k2,k1}(i+1);
            end
        end
        % newA(:, :, i) = -m0.a(:, :, i+1)'; % we are using row vector %% old version Matlab2012        
    else
        newA(i) = -m0.a(i+1); 
    end
end

% for dim = 1 : k
%     spec_fit = garchset('R', ar_order, 'Q', bekk_order, 'Display','off');
%     clear tCoeff;
%     [tCoeff, tErrors, tLLF] = garchfit(spec_fit, data(:,dim));
%     for i  = 1 : ar_order
%         newA(dim, dim, i) = tCoeff.AR(i)'; % we are using row vector
%     end
%     newC(dim, dim) = tCoeff.K;
%     for i = 1 : bekk_order
%         newB(dim,dim, i) = tCoeff.ARCH(i)'; % we are using row vector
%     end
% end

newA = reshape(newA, k*k*ar_order, 1);
newC = vech(newC);
newB = reshape(newB, k*k*bekk_order, 1);



function [newB, newC] = regresserror(Err, data, ar_order, bekk_order)
%% get the size
[m1,n1] = size(Err);
[m2,n2] = size(data);
assert(m1==m2);
assert(n1==n2);
%% discard the first ar_order+bekk_order
m = max(ar_order, bekk_order);
if m  > m2
    'Error: the model order needs to be smaller than the length of the data'
    pause();
end
%% prepare data for regression model
output =  Err .* Err;
input0 = data .* data;
output = output(m+1:end, :);
for i = 1 : size(output,1)
    temp = [1];
    for j = 1 : bekk_order
        temp = [temp,  input0(m+i-j, : )];
    end
    input(i,:) = temp;
end
% fit model for each dimension
for i = 1 : n1
    b(:,i) = regress(output(:,i), input);
end
% reshape the parameters
newC = zeros(n1);
for i = 1 : n1
    newC(i,i) = sqrt(abs(b(1,i)));
end
newB = zeros(n1,n1,bekk_order);
% for i = 1 : bekk_order
%     for j = 1 : n1
%         newB(j,j,i) = sqrt(abs(b(i+1, j)));
%     end
% end
for i = 1 : n1
    for j = 1 : n1
        for q = 1 : bekk_order
            newB(i,j,q) = sqrt(abs(b((q-1)*n1+j, i)));
        end
    end
end
