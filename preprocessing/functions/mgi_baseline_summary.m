function baseline = mgi_baseline_summary(sessions,cfg)
%MGI_BASELINE_SUMMARY Mouse-level summaries and statistics of baseline sessions.
%   baseline = mgi_baseline_summary(sessions,cfg), sessions from mgi_baseline_session.
%   Sessions of the same mouse are pooled.
%   baseline.movement  neuron table, mouse means, pooled CDF, significant fractions
%   baseline.intra     per-mouse and mouse-averaged CDFs of within-region partial R^2
%   baseline.inter     neuron table of signed partial r, mouse medians, preference fractions
%   baseline.stats     tests shown with the figures
    o = cfg.baseline;
    regions = cfg.regions;
    nR = numel(regions);
    mice = unique({sessions.mouse},'stable');
    [~,mouseOf] = ismember({sessions.mouse},mice);
    nM = numel(mice);
    G = cfg.grid.points;
    x = linspace(0,asinh(1/cfg.grid.asinhScale),G);
    r2Grid = cfg.grid.asinhScale*sinh(x);
    r2Grid(end) = 1;

    baseline = struct('mice',{mice(:)'},'regions',{regions},'targets',{o.targets}, ...
        'grid',struct('x',x,'r2',r2Grid));
    baseline.sessions = rmfield(sessions,{'movement','intra','inter'});

    movement = emptyTable({'mouse','conditionIndex','region','neuron','R2','P','Q','nullMeanR2','significant'});
    recorded = zeros(nM,nR);
    for s = 1:numel(sessions)
        recorded(mouseOf(s),:) = recorded(mouseOf(s),:) + sessions(s).recorded;
        for r = 1:nR
            m = sessions(s).movement{r};
            n = numel(m.R2);
            movement = appendRows(movement,struct('mouse',repmat(mouseOf(s),n,1), ...
                'conditionIndex',repmat(sessions(s).conditionIndex,n,1),'region',repmat(r,n,1), ...
                'neuron',m.neuron,'R2',m.R2,'P',m.P,'Q',NaN(n,1),'nullMeanR2',m.nullMeanR2, ...
                'significant',false(n,1)));
        end
    end
    for mi = 1:nM
        for r = 1:nR
            ix = movement.mouse == mi & movement.region == r;
            movement.Q(ix) = mgi_padjust(movement.P(ix),o.movementCorrection);
        end
    end
    movement.significant = movement.Q < o.alpha;
    mouseMean = NaN(nM,nR);
    pooledCDF = zeros(nR,G);
    significant = zeros(1,nR);
    uncorrected = zeros(1,nR);
    for r = 1:nR
        inRegion = movement.region == r;
        for mi = 1:nM
            mouseMean(mi,r) = mean(movement.R2(inRegion & movement.mouse == mi));
        end
        pooledCDF(r,:) = mgi_cdf_on_grid(movement.R2(inRegion),r2Grid)/nnz(inRegion);
        significant(r) = nnz(movement.significant(inRegion));
        uncorrected(r) = nnz(movement.P(inRegion) < o.alpha);
    end
    baseline.movement = struct('neurons',movement,'mouseMean',mouseMean, ...
        'recorded',recorded,'pooledCDF',pooledCDF,'significantCounts',significant, ...
        'significantFraction',significant./sum(recorded,1), ...
        'uncorrectedCounts',uncorrected,'uncorrectedFraction',uncorrected./sum(recorded,1), ...
        'correction',o.movementCorrection,'alpha',o.alpha);

    counts = zeros(nM,nR,G);
    nPairs = zeros(nM,nR);
    sums = zeros(nM,nR);
    for s = 1:numel(sessions)
        for r = 1:nR
            v = double(sessions(s).intra{r});
            counts(mouseOf(s),r,:) = counts(mouseOf(s),r,:) + reshape(mgi_cdf_on_grid(v,r2Grid),1,1,G);
            nPairs(mouseOf(s),r) = nPairs(mouseOf(s),r) + numel(v);
            sums(mouseOf(s),r) = sums(mouseOf(s),r) + sum(v);
        end
    end
    mouseCDF = counts./repmat(nPairs,[1 1 G]);
    baseline.intra = struct('mouseCDF',mouseCDF,'groupCDF',reshape(mean(mouseCDF,1),nR,G), ...
        'mouseMean',sums./nPairs,'nPairs',nPairs,'conditioning',o.intraConditioning);

    inter = emptyTable({'mouse','conditionIndex','seed','neuron','rA','rB','P','Q', ...
        'nullMeanA','nullMeanB','nullMeanDelta','preference'});
    for s = 1:numel(sessions)
        for r = 1:nR
            v = sessions(s).inter{r};
            n = numel(v.rA);
            inter = appendRows(inter,struct('mouse',repmat(mouseOf(s),n,1), ...
                'conditionIndex',repmat(sessions(s).conditionIndex,n,1),'seed',repmat(r,n,1), ...
                'neuron',v.neuron,'rA',v.rA,'rB',v.rB,'P',v.P,'Q',NaN(n,1), ...
                'nullMeanA',v.nullMeanA,'nullMeanB',v.nullMeanB,'nullMeanDelta',v.nullMeanDelta, ...
                'preference',zeros(n,1)));
        end
    end
    centroidA = NaN(nM,nR); centroidB = NaN(nM,nR);
    for mi = 1:nM
        for r = 1:nR
            ix = inter.mouse == mi & inter.seed == r;
            inter.Q(ix) = mgi_padjust(inter.P(ix),o.preferenceCorrection);
            centroidA(mi,r) = median(inter.rA(ix));
            centroidB(mi,r) = median(inter.rB(ix));
        end
    end
    excess = (inter.rB - inter.rA) - inter.nullMeanDelta;
    inter.preference(inter.Q < o.alpha & excess < 0) = 1;
    inter.preference(inter.Q < o.alpha & excess > 0) = 2;
    preferenceCounts = zeros(3,nR);
    for r = 1:nR
        ix = inter.seed == r;
        preferenceCounts(:,r) = [nnz(inter.preference(ix) == 1); nnz(inter.preference(ix) == 2); ...
            nnz(inter.preference(ix) == 0)];
    end
    baseline.inter = struct('neurons',inter,'centroidA',centroidA,'centroidB',centroidB, ...
        'centroidResidual',centroidB - centroidA,'preferenceCounts',preferenceCounts, ...
        'preferenceFraction',preferenceCounts./sum(preferenceCounts,1), ...
        'conditioning',o.interConditioning,'alpha',o.alpha);

    baseline.stats = statistics(baseline,regions);
end

function stats = statistics(baseline,regions)
    pairs = [1 2; 2 3; 1 3];
    labels = arrayfun(@(k) sprintf('%s vs %s',regions{pairs(k,1)},regions{pairs(k,2)}), ...
        (1:3)','UniformOutput',false);
    movement = baseline.movement.neurons;
    D = zeros(3,1); P = D;
    for k = 1:3
        [D(k),P(k)] = mgi_kstest2(movement.R2(movement.region == pairs(k,1)), ...
            movement.R2(movement.region == pairs(k,2)));
    end
    stats.movementCDF = struct('comparison',labels,'regionA',num2cell(pairs(:,1)), ...
        'regionB',num2cell(pairs(:,2)),'test','two-sided two-sample Kolmogorov-Smirnov, pooled neurons', ...
        'D',num2cell(D),'P',num2cell(P),'P_BH',num2cell(mgi_padjust(P,'bh')));

    statistic = zeros(3,1); P = statistic;
    for k = 1:3
        curves = squeeze(baseline.intra.mouseCDF(:,pairs(k,1),:) - baseline.intra.mouseCDF(:,pairs(k,2),:));
        if isvector(curves), curves = curves(:)'; end
        [statistic(k),P(k)] = mgi_signflip_test(curves);
    end
    stats.intraCDF = struct('comparison',labels,'regionA',num2cell(pairs(:,1)), ...
        'regionB',num2cell(pairs(:,2)), ...
        'test','two-sided mouse-level sign-flip test of the Kolmogorov-Smirnov statistic', ...
        'statistic',num2cell(statistic),'P',num2cell(P),'P_BH',num2cell(mgi_padjust(P,'bh')));

    nR = numel(regions);
    residualMean = zeros(nR,1); t = residualMean; df = t; P = t;
    for r = 1:nR
        test = mgi_ttest_onesample(baseline.inter.centroidResidual(:,r));
        residualMean(r) = test.mean; t(r) = test.t; df(r) = test.df; P(r) = test.P;
    end
    stats.interCentroid = struct('seed',regions(:), ...
        'test','two-sided one-sample t-test of mouse centroid residuals from the unity line', ...
        'meanResidual',num2cell(residualMean),'t',num2cell(t),'df',num2cell(df), ...
        'P',num2cell(P),'P_Holm',num2cell(mgi_padjust(P,'holm')));
end

function t = emptyTable(names)
    t = struct();
    for k = 1:numel(names)
        t.(names{k}) = zeros(0,1);
    end
end

function t = appendRows(t,rows)
    names = fieldnames(t);
    for k = 1:numel(names)
        t.(names{k}) = [t.(names{k}); rows.(names{k})(:)];
    end
end
