function auc = mgi_epoch_auc(windows,seconds,minValidFraction)
%MGI_EPOCH_AUC Area under the activity curve of each neuron and event over an epoch.
%   windows: neurons x epoch frames x events. AUC = mean activity x epoch
%   duration (seconds); NaN when fewer than minValidFraction of the epoch
%   frames are finite. Returns neurons x events.
    [n,f,e] = size(windows);
    finite = isfinite(windows);
    counts = sum(finite,2);
    values = windows;
    values(~finite) = 0;
    means = sum(values,2)./counts;
    means(counts < ceil(minValidFraction*f) | counts == 0) = NaN;
    auc = reshape(means*seconds,n,e);
end
