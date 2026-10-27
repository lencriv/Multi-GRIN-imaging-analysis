function out = mgi_correlation_change(before,after,kind,cfg,excludeMice)
%MGI_CORRELATION_CHANGE Change in the distribution of pairwise R^2 between two conditions.
%   out = mgi_correlation_change(before,after,'intra'|'inter',cfg,excludeMice)
%   For every mouse recorded in both conditions, the CDF of pairwise R^2 is
%   computed on the asinh grid in each condition (sessions pooled within
%   mouse). The plotted curve is the mouse average of before - after.
%   Two-sided two-sample KS on the pooled pairs; BH across the curves.
    G = cfg.grid.points;
    x = linspace(0,asinh(1/cfg.grid.asinhScale),G);
    r2Grid = cfg.grid.asinhScale*sinh(x);
    r2Grid(end) = 1;
    mice = intersect({before.mouse},{after.mouse},'stable');
    mice = mice(~ismember(mice,excludeMice));
    if strcmp(kind,'intra')
        labels = cfg.regions;
    else
        labels = cfg.regionPairLabels;
    end
    nM = numel(mice);
    out = struct([]);
    for k = 1:numel(labels)
        cdfBefore = zeros(nM,G); cdfAfter = zeros(nM,G);
        meanBefore = zeros(nM,1); meanAfter = zeros(nM,1);
        pooledBefore = cell(nM,1); pooledAfter = cell(nM,1);
        for m = 1:nM
            pooledBefore{m} = gather(before,mice{m},kind,k);
            pooledAfter{m} = gather(after,mice{m},kind,k);
            cdfBefore(m,:) = mgi_cdf_on_grid(pooledBefore{m},r2Grid)/numel(pooledBefore{m});
            cdfAfter(m,:) = mgi_cdf_on_grid(pooledAfter{m},r2Grid)/numel(pooledAfter{m});
            meanBefore(m) = mean(pooledBefore{m});
            meanAfter(m) = mean(pooledAfter{m});
        end
        a = cat(1,pooledBefore{:}); b = cat(1,pooledAfter{:});
        [D,P] = mgi_kstest2(a,b);
        entry = struct('kind',kind,'label',{labels{k}},'mice',{mice(:)'}, ...
            'grid',struct('x',x,'r2',r2Grid),'cdfBefore',cdfBefore,'cdfAfter',cdfAfter, ...
            'perMouseDifference',cdfBefore - cdfAfter,'difference',mean(cdfBefore - cdfAfter,1), ...
            'nBefore',numel(a),'nAfter',numel(b),'D',D,'P',P,'P_BH',NaN, ...
            'test','two-sided two-sample Kolmogorov-Smirnov, pooled neuron pairs', ...
            'mouseMeanBefore',meanBefore,'mouseMeanAfter',meanAfter);
        if isempty(out), out = entry; else, out(end+1) = entry; end
    end
    adjusted = mgi_padjust([out.P],'bh');
    for k = 1:numel(out), out(k).P_BH = adjusted(k); end
end

function values = gather(features,mouse,kind,k)
    values = zeros(0,1);
    for s = find(strcmp({features.mouse},mouse))
        v = double(features(s).(kind){k});
        values = [values; v(:)];
    end
end
