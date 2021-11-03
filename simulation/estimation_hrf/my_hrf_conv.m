function X = my_hrf_conv(U, fmri_spec, xBF)
% convoluting with hrf(16HZ)
% the onset time is better to be multiple TRs or some specified dt,
% otherwise the discreted convolution between the hrf and the event train cannot match;
% some interpolation
clear X
nconditions = fmri_spec.nconditions;
for i = 1 : nconditions
    X_temp = [];
    for p = 1 : size(xBF.bf,2)
        X_temp = [X_temp, conv(U(i).u, xBF.bf(:,p))];
    end
    % downsampling to 2HZ
    X_temp = X_temp(fmri_spec.timing.fmri_t0:fmri_spec.upsampling_factor:end-(length(xBF.bf)-1),:);    
    % orthogonalise
    % X_temp = spm_orth(X_temp);
    % record
    X{i} = X_temp;
end