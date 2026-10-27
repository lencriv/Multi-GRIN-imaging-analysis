function step = mgi_nice_step(span,maxIntervals)
%MGI_NICE_STEP Smallest 1-2-5 tick step dividing span into at most maxIntervals intervals.
    if ~(span > 0) || ~isfinite(span)
        step = 1;
        return;
    end
    base = 10^floor(log10(span/maxIntervals));
    for m = [1 2 5 10]
        step = m*base;
        if span/step <= maxIntervals*(1 + 1e-9), return; end
    end
end
