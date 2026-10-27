function y = mgi_fill_gaps(x,maxGap)
%MGI_FILL_GAPS Linear gap filling as fillmissing(x,'linear','MaxGap',maxGap).
%   fillmissing is used when available; otherwise interior NaN runs whose
%   bounding samples are <= maxGap apart are interpolated.
    x = double(x(:));
    if exist('OCTAVE_VERSION','builtin') == 0 && exist('fillmissing','file') == 2
        y = fillmissing(x,'linear','MaxGap',maxGap);
        return;
    end
    y = x;
    n = numel(x);
    missing = isnan(x);
    i = 1;
    while i <= n
        if ~missing(i), i = i + 1; continue; end
        j = i;
        while j < n && missing(j + 1), j = j + 1; end
        left = i - 1; right = j + 1;
        if left >= 1 && right <= n && right - left <= maxGap
            y(i:j) = x(left) + (x(right) - x(left))*((i:j)' - left)/(right - left);
        end
        i = j + 1;
    end
end
