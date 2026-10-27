function p = mgi_tcdf(t,df)
%MGI_TCDF Student t lower-tail probability.
    t = double(t); df = double(df);
    if isscalar(df), df = repmat(df,size(t)); end
    p = NaN(size(t));
    ok = isfinite(t) & isfinite(df) & df > 0;
    tail = 0.5*betainc(df(ok)./(df(ok) + t(ok).^2),df(ok)/2,0.5);
    upper = t(ok) > 0;
    tail(upper) = 1 - tail(upper);
    p(ok) = tail;
    p(isinf(t) & t > 0) = 1;
    p(isinf(t) & t < 0) = 0;
end
