function lags = mgi_shift_lags(nFrames,minShift,count,distinct)
%MGI_SHIFT_LAGS Circular-shift lags drawn from [minShift, nFrames - minShift].
%   distinct = true draws without replacement (at most every admissible lag).
    admissible = minShift:(nFrames - minShift);
    if isempty(admissible)
        error('MGI:shiftLags','No admissible circular shifts.');
    end
    if distinct
        lags = admissible(randperm(numel(admissible),min(count,numel(admissible))));
    else
        lags = admissible(randi(numel(admissible),1,count));
    end
end
