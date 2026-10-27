function [average,events] = mgi_event_average(Z,onsets,half)
%MGI_EVENT_AVERAGE Mean activity of each neuron over events (neurons x (2*half+1)).
%   Column half+1 is the onset frame. Samples outside the recording or not
%   finite are left out of the mean; entries without any sample are NaN.
%   events (1 x columns) is the number of events whose window covers each
%   column.
    [n,T] = size(Z);
    width = 2*half + 1;
    total = zeros(n,width);
    counts = zeros(n,width);
    events = zeros(1,width);
    for e = 1:numel(onsets)
        first = onsets(e) - half;
        source = max(1,first):min(T,onsets(e) + half);
        if isempty(source), continue; end
        columns = source - first + 1;
        values = Z(:,source);
        finite = isfinite(values);
        values(~finite) = 0;
        total(:,columns) = total(:,columns) + values;
        counts(:,columns) = counts(:,columns) + finite;
        events(columns) = events(columns) + 1;
    end
    average = total./counts;
    average(counts == 0) = NaN;
end
