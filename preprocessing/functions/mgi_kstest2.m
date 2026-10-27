function [D,P] = mgi_kstest2(a,b)
%MGI_KSTEST2 Two-sided two-sample Kolmogorov-Smirnov test (asymptotic P, as kstest2).
    a = double(a(isfinite(a))); b = double(b(isfinite(b)));
    a = a(:); b = b(:);
    D = NaN; P = NaN;
    if isempty(a) || isempty(b), return; end
    if exist('OCTAVE_VERSION','builtin') == 0 && exist('kstest2','file') == 2
        [~,P,D] = kstest2(a,b);
        return;
    end
    points = unique([a; b]);
    D = max(abs(ecdfAt(sort(a),points) - ecdfAt(sort(b),points)));
    en = sqrt(numel(a)*numel(b)/(numel(a) + numel(b)));
    lambda = max((en + 0.12 + 0.11/en)*D,0);
    j = (1:101)';
    P = min(max(2*sum((-1).^(j - 1).*exp(-2*lambda^2*j.^2)),0),1);
end

function F = ecdfAt(sorted,points)
    n = numel(sorted);
    [~,order] = sort([sorted; points]);
    isSample = order <= n;
    running = cumsum(isSample);
    F = running(~isSample)/n;
end
