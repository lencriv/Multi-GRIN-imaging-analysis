function Z = mgi_zscore_activity(session,regions)
%MGI_ZSCORE_ACTIVITY z-scored denoised activity per region (neurons x frames).
%   Z = mgi_zscore_activity(session,{'M1','DMS','VLT'})
%   Each neuron's CNMF-E denoised trace is z-scored over the session;
%   constant traces become zero.
    Z = cell(1,numel(regions));
    for r = 1:numel(regions)
        C = double(session.neural.(regions{r}).denoised);
        mu = mean(C,2);
        sigma = std(C,0,2);
        sigma(sigma == 0) = 1;
        Z{r} = (C - mu)./sigma;
    end
end
