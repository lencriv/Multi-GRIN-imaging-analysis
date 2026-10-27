function out = mgi_transient_rate_comparison(before,after,cfg,excludeMice)
%MGI_TRANSIENT_RATE_COMPARISON Ca2+ transient-rate distributions of two conditions.
%   out = mgi_transient_rate_comparison(before,after,cfg,excludeMice)
%   before/after are mgi_session_features arrays. Per region: neurons with
%   >= cfg.transientRate.minEvents events; linear mixed-effects model
%   rate ~ condition + (1|mouse); design-effect corrected s.e.m.;
%   histogram proportions on 0..97.5th percentile of the pooled rates
%   (proportions of all neurons of the condition).
    o = cfg.transientRate;
    before = before(~ismember({before.mouse},excludeMice));
    after = after(~ismember({after.mouse},excludeMice));
    out = struct([]);
    for r = 1:numel(cfg.regions)
        [a,mouseA] = gather(before,r,o.minEvents);
        [b,mouseB] = gather(after,r,o.minEvents);
        y = [a; b];
        group = [zeros(numel(a),1); ones(numel(b),1)];
        model = mgi_lme_ri(y,[ones(numel(y),1) group],[mouseA; mouseB],o.lmeFitMethod);
        xmax = mgi_prctile(y,o.xLimitPercentile);
        edges = linspace(0,xmax,o.nBins + 1);
        entry = struct('region',cfg.regions{r},'valuesBefore',a,'valuesAfter',b, ...
            'mouseBefore',{mouseA},'mouseAfter',{mouseB}, ...
            'nBefore',numel(a),'nAfter',numel(b), ...
            'nMice',numel(unique([mouseA; mouseB])), ...
            'estimate',model.beta(2),'t',model.t(2),'df',model.df,'P',model.P(2), ...
            'test','linear mixed-effects model, rate ~ condition + (1|mouse)', ...
            'designEffectBefore',mgi_design_effect(a,mouseA,o.iccFitMethod), ...
            'designEffectAfter',mgi_design_effect(b,mouseB,o.iccFitMethod), ...
            'xmax',xmax,'edges',edges,'centers',edges(1:end-1) + diff(edges)/2, ...
            'proportionBefore',proportions(a,edges),'proportionAfter',proportions(b,edges));
        if isempty(out), out = entry; else, out(end+1) = entry; end
    end
end

function [values,mice] = gather(features,r,minEvents)
    values = zeros(0,1); mice = cell(0,1);
    for s = 1:numel(features)
        keep = features(s).events{r} >= minEvents & isfinite(features(s).rate{r});
        v = features(s).rate{r}(keep);
        values = [values; v(:)];
        mice = [mice; repmat({features(s).mouse},numel(v),1)];
    end
end

function p = proportions(values,edges)
    p = zeros(1,numel(edges) - 1);
    if isempty(values), return; end
    inside = values(values >= edges(1) & values <= edges(end));
    bins = min(numel(edges) - 1,max(1,sum(inside(:) >= edges(1:end-1),2)));
    p = accumarray(bins,1,[numel(edges) - 1 1])'/numel(values);
end
