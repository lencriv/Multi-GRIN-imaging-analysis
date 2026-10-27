function de = mgi_design_effect(values,cluster,method)
%MGI_DESIGN_EFFECT Cluster-corrected mean and s.e.m. of neuron values.
%   de = mgi_design_effect(values,mouse,'ML')
%   ICC from value ~ 1 + (1|mouse); DEFF = 1 + (mbar - 1)*ICC;
%   s.e.m. = SD/sqrt(n)*sqrt(DEFF); nEff = n/DEFF.
    if nargin < 3, method = 'ML'; end
    ok = isfinite(values(:));
    v = double(values(ok)); c = cluster(ok);
    n = numel(v);
    de = struct('n',n,'mean',NaN,'sem',NaN,'icc',0,'designEffect',1,'nEff',n);
    if n == 0, return; end
    [~,~,g] = unique(c(:));
    de.mean = mean(v);
    if max(g) >= 2 && n > max(g)
        fit = mgi_lme_ri(v,ones(n,1),g,method);
        if isfinite(fit.icc), de.icc = fit.icc; end
    end
    de.designEffect = max(1,1 + (n/max(g) - 1)*de.icc);
    de.nEff = n/de.designEffect;
    if n > 1, de.sem = std(v)/sqrt(n)*sqrt(de.designEffect); end
end
