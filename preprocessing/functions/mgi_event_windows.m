function windows = mgi_event_windows(Z,onsets,half)
%MGI_EVENT_WINDOWS Activity around each onset (neurons x (2*half+1) x events).
%   Column half+1 is the onset frame; samples outside the recording are NaN.
    [n,T] = size(Z);
    width = 2*half + 1;
    windows = NaN(n,width,numel(onsets));
    for e = 1:numel(onsets)
        first = onsets(e) - half;
        source = max(1,first):min(T,onsets(e) + half);
        if isempty(source), continue; end
        windows(:,source - first + 1,e) = Z(:,source);
    end
end
