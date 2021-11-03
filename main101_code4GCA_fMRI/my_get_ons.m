function U = my_get_ons(fmri_spec, subj)
% Output:
%   U     - (1 x n)   struct array of (n) trial-specific structures
%   U(i).name   - cell of names for each input or cause
%   U(i).u      - inputs or stimulus function matrix
%   U(i).dt     - time bin (seconds)
%   U(i).ons    - onsets    (in SPM.xBF.UNITS)
%   U(i).dur    - durations (in SPM.xBF.UNITS)

onset = fmri_spec.onset{subj};
numscans = fmri_spec.datalength(subj);
nconditions = fmri_spec.nconditions;
upsampling_factor = fmri_spec.upsampling_factor;
U = fmri_spec.U;
for i = 1 : nconditions
    U(i).u = zeros(numscans *  upsampling_factor,1); 
    if U(i).dur == 0
        % upsampling to 16HZ(0.5*32)
        index =  round(onset.sot{i}(:,1) * upsampling_factor);
        if index(1) == 0
            index(1) = 1;
        end
        U(i).u(index) = 1;
    else
        onset_tp = round(onset.sot{i}(:,1) * upsampling_factor);
        if onset_tp(1) == 0
            onset_tp(1) = 1;
        end
        U(i).u(onset_tp:onset_tp+U(i).dur-1) = 1;
    end
end