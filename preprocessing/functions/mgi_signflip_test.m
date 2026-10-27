function [statistic,P] = mgi_signflip_test(curves)
%MGI_SIGNFLIP_TEST Mouse-level sign-flip test of the maximum absolute mean curve.
%   curves is mice x grid (per-mouse CDF differences). All 2^n sign patterns
%   are enumerated for n <= 15 mice; otherwise 10,000 random patterns.
    n = size(curves,1);
    statistic = max(abs(mean(curves,1)));
    if n == 0, P = NaN; return; end
    if n <= 15
        codes = (0:2^n - 1)';
        signs = zeros(numel(codes),n);
        for j = 1:n
            signs(:,j) = 2*double(bitget(codes,j)) - 1;
        end
        reference = max(abs(signs*curves/n),[],2);
        P = mean(reference >= statistic - 1e-12);
    else
        signs = 2*(rand(10000,n) > 0.5) - 1;
        reference = max(abs(signs*curves/n),[],2);
        P = (1 + sum(reference >= statistic - 1e-12))/10001;
    end
end
