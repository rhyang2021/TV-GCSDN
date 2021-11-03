function glmresult = my_deconvolution_new(fmri_spec, subj, xBF, fmri_data)
%% Step 0: movement
X1 = fmri_data{subj};

%% step 1: account for sudden movement
% move =  fmri_spec.motion{subj};
% tmove = [0,0; sqrt(sum(diff(move(:,1:3)).^2,2)), sqrt(sum(diff(move(:,4:6)).^2,2))]; % the first scan get no movement
% X1 = filtermovement(tmove', X1');
% 
%% step 2: regress out movement
move_design =  [fmri_spec.motion{subj}, ones(size(fmri_spec.motion{subj},1),1)];
glmbeta1 = move_design \ X1;
X1 = X1 - move_design * glmbeta1;
% 
%% step 3: regress out trend
T = size(X1,1);
trend_design = [(1:T)', (1:T)'.^2, (1:T)'.^3];
glmbeta2 = trend_design \ X1;
X1 = X1 - trend_design * glmbeta2;

% % denoise
% dec = mdwtdec('c',X1,2,'db2');
% X1 = mswden('den',dec,'sqtwolog','sln');

%% Step 4: making event train
U = my_get_ons(fmri_spec, subj);
% step 2: convoluting with hrf
% the onset time is better to be multiple TRs or some specified dt, otherwise 
% the discreted convolution between the hrf and the event train cannot match;
% some interpolation
for roi = 1:3
    X = my_hrf_conv_new(U, fmri_spec, xBF,roi);
    % step 3: getting residual process by regressing out
    % event * hrf and motion up to the second order
    designmatrix = [];
    % adding different stimulus
    for i = 1 : fmri_spec.nconditions
        designmatrix = [designmatrix, X{i}];
    end
    % adding motion and constant
    % (If we have the WM, GM, CSF, we can add them in; but we cannot use the 
    % mean signal among all brain regions of interest)
    designmatrix = [designmatrix, ones(size(X{1},1),1)];
    glmbeta = designmatrix \ X1(:,roi);
    glmresult(:,roi) = X1(:,roi) -  designmatrix * glmbeta;
    
%     % % % regress out trend
%     T = size(X1,1);
%     trend_design = [(1:T)'];
%     glmbeta2 = trend_design \ X1(:,roi);
%     X1(:,roi) = X1(:,roi) - trend_design * glmbeta2;
end