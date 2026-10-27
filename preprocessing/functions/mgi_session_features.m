function features = mgi_session_features(session,cfg)
%MGI_SESSION_FEATURES Transient rates and pairwise correlations of one session.
%   features = mgi_session_features(session,cfg)
%   features.rate{r}, .events{r}  transient rate and event count of every
%                                 recorded neuron (mgi_transient_rate)
%   features.intra{r}             R^2 of every unique within-region pair
%   features.inter{p}             R^2 of every pair across cfg.regionPairs(p,:)
%   Correlations use z-scored activity on frames with valid orofacial
%   speed (mgi_session_inputs).
    inputs = mgi_session_inputs(session,cfg);
    nR = numel(cfg.regions);
    nP = size(cfg.regionPairs,1);
    features = struct('mouse',inputs.mouse,'conditionIndex',inputs.conditionIndex, ...
        'globalMouseIndex',inputs.globalMouseIndex,'recorded',inputs.recorded, ...
        'nFrames',inputs.nFrames,'rate',{cell(1,nR)},'events',{cell(1,nR)}, ...
        'intra',{cell(1,nR)},'inter',{cell(1,nP)});
    for r = 1:nR
        [features.rate{r},features.events{r}] = mgi_transient_rate( ...
            session.neural.(cfg.regions{r}).deconvolved,inputs.frameRate);
        features.intra{r} = single(mgi_pairwise_r2(inputs.Y{r}));
    end
    for p = 1:nP
        pair = cfg.regionPairs(p,:);
        features.inter{p} = single(mgi_pairwise_r2(inputs.Y{pair(1)},inputs.Y{pair(2)}));
    end
end
