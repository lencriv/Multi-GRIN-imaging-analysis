function y = mgi_movmean(x,window)
%MGI_MOVMEAN Centered moving mean omitting NaN (movmean(x,window,'omitnan')).
    x = double(x(:));
    n = numel(x);
    k = max(1,round(window));
    if mod(k,2) == 1
        before = (k - 1)/2; after = before;
    else
        before = k/2; after = k/2 - 1;
    end
    ok = isfinite(x);
    z = x; z(~ok) = 0;
    cs = [0; cumsum(z)];
    cn = [0; cumsum(double(ok))];
    i = (1:n)';
    lo = max(1,i - before);
    hi = min(n,i + after);
    counts = cn(hi + 1) - cn(lo);
    y = (cs(hi + 1) - cs(lo))./counts;
    y(counts == 0) = NaN;
end
