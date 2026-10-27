function q = mgi_prctile(x,p)
%MGI_PRCTILE Percentile with MATLAB prctile interpolation.
    x = sort(double(x(isfinite(x))));
    n = numel(x);
    if n == 0, q = NaN(size(p)); return; end
    if n == 1, q = repmat(x,size(p)); return; end
    position = min(max(n*p/100 + 0.5,1),n);
    q = interp1(1:n,x,position);
end
