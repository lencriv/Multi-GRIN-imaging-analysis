function r = mgi_ttest_onesample(d)
%MGI_TTEST_ONESAMPLE Two-sided one-sample t-test of mean(d) against zero.
    d = double(d(isfinite(d)));
    n = numel(d);
    r = struct('n',n,'mean',NaN,'t',NaN,'df',NaN,'P',NaN);
    if n < 2, return; end
    r.mean = mean(d);
    r.df = n - 1;
    sd = std(d);
    if sd == 0
        if r.mean ~= 0, r.t = sign(r.mean)*Inf; r.P = 0; end
        return;
    end
    r.t = r.mean/(sd/sqrt(n));
    r.P = 2*mgi_tcdf(-abs(r.t),r.df);
end
