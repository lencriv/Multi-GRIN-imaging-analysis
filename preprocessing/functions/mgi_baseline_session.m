function result = mgi_baseline_session(inputs,cfg)
%MGI_BASELINE_SESSION Movement coupling, partial correlations and region preference of one session.
%   result = mgi_baseline_session(inputs,cfg)
%   inputs from mgi_session_inputs. For each region r:
%   result.movement{r}  neuron R^2 with orofacial speed, circular-shift P
%   result.intra{r}     squared pairwise partial r (other regions removed)
%   result.inter{r}     signed partial r with each target region's mean
%                       activity (third region removed) and preference null
    o = cfg.baseline;
    nRegions = numel(inputs.Y);
    T = inputs.nFrames;
    lagMin = max(1,round(o.minShiftSeconds*inputs.frameRate));
    [PCs,population] = mgi_region_pcs(inputs.Y,o.nPC);
    rng(o.seed + 1000*inputs.globalMouseIndex + inputs.conditionIndex,'twister');
    movementLags = mgi_shift_lags(T,lagMin,o.movementShuffles,false);
    preferenceLags = mgi_shift_lags(T,lagMin,o.preferenceShuffles,true);
    result = struct('mouse',inputs.mouse,'conditionIndex',inputs.conditionIndex, ...
        'globalMouseIndex',inputs.globalMouseIndex,'nFrames',T, ...
        'recorded',inputs.recorded,'analyzable',cellfun(@(y) size(y,2),inputs.Y), ...
        'movementShuffles',numel(movementLags),'preferenceShuffles',numel(preferenceLags), ...
        'movement',{cell(1,nRegions)},'intra',{cell(1,nRegions)},'inter',{cell(1,nRegions)});
    for r = 1:nRegions
        if cfg.verbose
            fprintf('  %s %s: %d neurons\n',inputs.mouse,cfg.regions{r},size(inputs.Y{r},2));
        end
        coupling = mgi_movement_coupling(inputs.Y{r},inputs.movement,movementLags,o.neuronBatchSize);
        coupling.neuron = inputs.neurons{r}(:);
        result.movement{r} = coupling;

        Q = mgi_conditioning_basis(setdiff(1:nRegions,r),PCs,population,o.intraConditioning);
        result.intra{r} = single(mgi_pairwise_r2(inputs.Y{r} - Q*(Q'*inputs.Y{r})));

        partial = mgi_inter_partial_r(inputs.Y,PCs,population,r,o.targets{r},o.interConditioning);
        null = mgi_preference_null(inputs.Y{r},partial,preferenceLags,o.neuronBatchSize,o.lagChunkSize);
        result.inter{r} = struct('neuron',inputs.neurons{r}(:),'rA',partial.rA,'rB',partial.rB, ...
            'P',null.P,'nullMeanA',null.nullMeanA,'nullMeanB',null.nullMeanB, ...
            'nullMeanDelta',null.nullMeanDelta);
    end
end
