function [p,z,W] = mgi_ranksum(a,b)
%MGI_RANKSUM Two-sided Wilcoxon rank-sum test, normal approximation.
%   [p,z,W] = mgi_ranksum(a,b) on the finite values of a and b.
%   W is the rank sum of a; z includes the tie and continuity corrections
%   (as ranksum(a,b,'method','approximate')) and is positive when a tends
%   to be larger than b.
    a = double(a(isfinite(a)));
    b = double(b(isfinite(b)));
    p = NaN; z = NaN; W = NaN;
    na = numel(a); nb = numel(b); N = na + nb;
    if na == 0 || nb == 0, return; end
    [sorted,order] = sort([a(:); b(:)]);
    ranks = zeros(N,1);
    ties = 0;
    k = 1;
    while k <= N
        last = k;
        while last < N && sorted(last + 1) == sorted(k), last = last + 1; end
        ranks(order(k:last)) = (k + last)/2;
        t = last - k + 1;
        ties = ties + t^3 - t;
        k = last + 1;
    end
    W = sum(ranks(1:na));
    centered = W - na*(N + 1)/2;
    variance = na*nb*((N + 1) - ties/(N*(N - 1)))/12;
    if variance <= 0
        p = 1; z = 0; return;
    end
    z = (centered - 0.5*sign(centered))/sqrt(variance);
    p = min(1,erfc(abs(z)/sqrt(2)));
end
