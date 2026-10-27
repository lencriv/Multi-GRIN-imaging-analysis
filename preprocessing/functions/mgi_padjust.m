function q = mgi_padjust(p,method)
%MGI_PADJUST Adjust P values: 'bh', 'holm', 'bonferroni' or 'none'.
    q = NaN(size(p));
    ok = isfinite(p);
    v = double(p(ok));
    v = v(:);
    m = numel(v);
    if m == 0, return; end
    switch lower(method)
        case 'none'
            adjusted = v;
        case 'bonferroni'
            adjusted = min(1,v*m);
        case 'holm'
            [sorted,ix] = sort(v);
            adjusted = zeros(m,1);
            adjusted(ix) = min(1,cummax(sorted.*(m - (0:m-1)')));
        case 'bh'
            [sorted,ix] = sort(v);
            adjusted = zeros(m,1);
            adjusted(ix) = min(1,flipud(cummin(flipud(sorted.*m./(1:m)'))));
        otherwise
            error('MGI:padjust','Unknown adjustment %s.',method);
    end
    q(ok) = adjusted;
end
