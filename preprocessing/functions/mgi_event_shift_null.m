function [nullPre,nullPost] = mgi_event_shift_null(Z,onsets,epochFrames,epochSeconds,shuffles,minShift,minEvents,minValidFraction)
%MGI_EVENT_SHIFT_NULL Pre- and post-epoch AUC at circularly shifted event trains.
%   The whole train of onsets is shifted by one random lag in
%   [minShift, T - minShift] per shuffle (event number and intervals kept);
%   each neuron's value is the mean AUC over the shifted events with at
%   least minEvents valid events. Returns neurons x shuffles.
    [n,T] = size(Z);
    nullPre = NaN(n,shuffles); nullPost = nullPre;
    firstCenter = epochFrames + 1;
    lastCenter = T - epochFrames + 1;
    onsets = round(onsets(isfinite(onsets)));
    onsets = onsets(onsets >= 1 & onsets <= T);
    if firstCenter > lastCenter || isempty(onsets), return; end
    if T <= 2*minShift
        error('MGI:eventShift','Recording too short for the minimum circular shift.');
    end
    centers = firstCenter:lastCenter;
    nCenters = numel(centers);
    preByCenter = slidingAUC(Z,centers - epochFrames,centers - 1,epochFrames,epochSeconds,minValidFraction);
    postByCenter = slidingAUC(Z,centers,centers + epochFrames - 1,epochFrames,epochSeconds,minValidFraction);
    preByCenter(:,nCenters + 1) = NaN;
    postByCenter(:,nCenters + 1) = NaN;
    batch = max(1,min([100,floor(5e6/max(1,n*numel(onsets))),shuffles]));
    first = 1;
    while first <= shuffles
        last = min(first + batch - 1,shuffles);
        lags = randi([minShift,T - minShift],1,last - first + 1);
        shifted = mod(onsets(:) + lags - 1,T) + 1;
        column = shifted - firstCenter + 1;
        column(column < 1 | column > nCenters) = nCenters + 1;
        nullPre(:,first:last) = eventMeans(preByCenter,column,minEvents);
        nullPost(:,first:last) = eventMeans(postByCenter,column,minEvents);
        first = last + 1;
    end
end

function auc = slidingAUC(Z,starts,ends,epochFrames,epochSeconds,minValidFraction)
    finite = isfinite(Z);
    values = Z; values(~finite) = 0;
    cv = [zeros(size(Z,1),1), cumsum(values,2)];
    cc = [zeros(size(Z,1),1), cumsum(double(finite),2)];
    counts = cc(:,ends + 1) - cc(:,starts);
    auc = (cv(:,ends + 1) - cv(:,starts))./counts*epochSeconds;
    auc(counts == 0 | counts < ceil(minValidFraction*epochFrames)) = NaN;
end

function means = eventMeans(aucByCenter,column,minEvents)
    [nEvents,nShuffles] = size(column);
    n = size(aucByCenter,1);
    values = reshape(aucByCenter(:,column(:)),n,nEvents,nShuffles);
    finite = isfinite(values);
    counts = sum(finite,2);
    values(~finite) = 0;
    means = sum(values,2)./counts;
    means(counts == 0 | counts < minEvents) = NaN;
    means = reshape(means,n,nShuffles);
end
